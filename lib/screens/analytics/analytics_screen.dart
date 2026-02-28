import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/aggregate_provider.dart';
import '../goals/goal_detail_screen.dart';

// ─────────────────────────────────────────────────────────
// AnalyticsScreen  (PRD §5.7)
//
// Overview Tab:
//   2x2 stat grid: Total Saved, Total Target, Active Goals, Completed
//   Fifth stat (full width): Overdue count (amber when > 0)
//
// Per Goal Tab:
//   Vertical bar chart (CustomPaint) showing each goal's % progress
//
// Insight Cards:
//   - Closest to Completion
//   - Needs Attention (urgencyScore formula §7.4, Fix #14 guard)
//   - Recovery Needed (list of overdue goals, hidden if none)
// ─────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.colorNeonGreen,
          unselectedLabelColor: AppTheme.colorTextSecondary,
          indicatorColor: AppTheme.colorNeonGreen,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Per Goal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverviewTab(),
          _PerGoalTab(),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregate  = ref.watch(aggregateProvider);
    final active     = ref.watch(activeGoalsProvider);
    final completed  = ref.watch(completedGoalsProvider);
    final overdue    = ref.watch(overdueGoalsProvider);
    final goals      = ref.watch(goalsProvider).value ?? [];

    // Insights
    final closestGoal    = _findClosestToCompletion(active);
    final needsAttention = _findNeedsAttention(active);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 2×2 Stat grid
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              label: 'Total Saved',
              value: inrCompact(aggregate.totalSaved),
              color: AppTheme.colorNeonGreen,
            ),
            _StatCard(
              label: 'Total Target',
              value: inrCompact(aggregate.totalTarget),
              color: AppTheme.colorTextPrimary,
            ),
            _StatCard(
              label: 'Active Goals',
              value: active.length.toString(),
              color: AppTheme.colorTextPrimary,
            ),
            _StatCard(
              label: 'Completed',
              value: completed.length.toString(),
              color: AppTheme.colorSuccess,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fifth stat: Overdue (full width, amber when > 0)
        _StatCard(
          label: 'Overdue Goals',
          value: overdue.length.toString(),
          color: overdue.isEmpty
              ? AppTheme.colorTextSecondary
              : AppTheme.colorRecoveryAmber,
          fullWidth: true,
        ),

        const SizedBox(height: 28),
        const Text('Insights', style: AppTheme.titleLarge),
        const SizedBox(height: 16),

        // Closest to Completion
        if (closestGoal != null)
          _InsightCard(
            icon: Icons.emoji_events_outlined,
            title: 'Closest to Completion',
            subtitle: closestGoal.title,
            value:
                '${(closestGoal.progressPercent * 100).round()}% complete',
            goal: closestGoal,
            color: AppTheme.colorNeonGreen,
          ),

        // Needs Attention (urgencyScore — Fix #14)
        if (needsAttention != null)
          _InsightCard(
            icon: Icons.priority_high,
            title: 'Needs Attention',
            subtitle: needsAttention.title,
            value: needsAttention.daysRemaining != null
                ? '${needsAttention.daysRemaining} days left'
                : 'No deadline',
            goal: needsAttention,
            color: AppTheme.colorRecoveryAmber,
          ),

        // Recovery Needed (hidden if none)
        if (overdue.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.colorSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.colorRecoveryAmber.withOpacity(0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.replay_outlined,
                      color: AppTheme.colorRecoveryAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recovery Needed',
                      style: AppTheme.titleLarge.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...overdue.map(
                  (g) => _RecoveryGoalRow(goal: g),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  // Closest to completion (highest progressPercent, not yet complete)
  Goal? _findClosestToCompletion(List<Goal> active) {
    if (active.isEmpty) return null;
    Goal? best;
    for (final g in active) {
      if (best == null || g.progressPercent > best.progressPercent) {
        best = g;
      }
    }
    return best;
  }

  // Needs Attention (urgencyScore §7.4, Fix #14)
  Goal? _findNeedsAttention(List<Goal> active) {
    final eligible = active.where((g) => g.targetDate != null).toList();
    if (eligible.isEmpty) return null;
    return eligible.reduce(
      (a, b) => _urgencyScore(a) > _urgencyScore(b) ? a : b,
    );
  }

  /// urgencyScore (PRD §7.4, Fix #14).
  /// Returns 0.0 for goals without deadline, completed, overdue,
  /// or when days <= 0.
  double _urgencyScore(Goal g) {
    if (g.targetDate == null) return 0.0;
    if (g.isCompleted) return 0.0;
    if (g.isOverdue) return 0.0;  // excluded per PRD §7.4
    final days = g.daysRemaining ?? 0;
    if (days <= 0) return 0.0;    // Fix #14 guard
    final progress = g.progressPercent;  // already clamped 0..1
    final pressure = 1.0 / (days + 1);
    return (1.0 - progress) * pressure;
  }
}

// ── Per Goal Tab ─────────────────────────────────────────
class _PerGoalTab extends ConsumerWidget {
  const _PerGoalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).value ?? [];

    if (goals.isEmpty) {
      return const Center(
        child: Text(
          'No goals to display.',
          style: AppTheme.bodyMedium,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Progress by Goal',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 260,
          child: CustomPaint(
            painter: _BarChartPainter(goals: goals),
          ),
        ),
        const SizedBox(height: 32),
        // Goal list with individual % bars
        ...goals.map((g) => _GoalProgressRow(goal: g)),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTheme.labelSmall),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headlineMedium.copyWith(
              color: color,
              fontSize: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.goal,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Goal goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GoalDetailScreen(goalId: goal.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.colorSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.labelSmall),
                    Text(
                      subtitle,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.colorTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: AppTheme.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryGoalRow extends StatelessWidget {
  const _RecoveryGoalRow({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final days = (goal.daysRemaining ?? 0).abs();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GoalDetailScreen(goalId: goal.id),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_outlined,
              color: AppTheme.colorRecoveryAmber,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                goal.title,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.colorTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$days day${days == 1 ? '' : 's'} overdue',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.colorRecoveryAmber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final color = goal.isOverdue
        ? AppTheme.colorRecoveryAmber
        : goal.isCompleted
            ? AppTheme.colorNeonGreen
            : hexToColor(goal.accentColorHex);
    final pct = (goal.progressPercent * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.colorTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: AppTheme.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progressPercent,
              backgroundColor: AppTheme.colorSurfaceAlt,
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bar Chart (CustomPaint) ───────────────────────────────
class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.goals});
  final List<Goal> goals;

  @override
  void paint(Canvas canvas, Size size) {
    if (goals.isEmpty) return;

    final barWidth = (size.width / goals.length) * 0.6;
    final spacing  = size.width / goals.length;
    final maxH     = size.height - 40;

    for (var i = 0; i < goals.length; i++) {
      final g      = goals[i];
      final pct    = g.progressPercent;
      final barH   = maxH * pct;
      final x      = i * spacing + (spacing - barWidth) / 2;
      final y      = size.height - 30 - barH;

      final color = g.isOverdue
          ? AppTheme.colorRecoveryAmber
          : g.isCompleted
              ? AppTheme.colorNeonGreen
              : hexToColor(g.accentColorHex);

      // Background bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - 30 - maxH, barWidth, maxH),
          const Radius.circular(4),
        ),
        Paint()..color = AppTheme.colorSurface,
      );

      // Filled bar
      if (barH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barWidth, barH),
            const Radius.circular(4),
          ),
          Paint()..color = color,
        );
      }

      // Percent label
      final pctLabel = '${(pct * 100).round()}%';
      final tp = TextPainter(
        text: TextSpan(
          text: pctLabel,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: AppTheme.colorTextSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x + (barWidth - tp.width) / 2, y - 14),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.goals != goals;
}
