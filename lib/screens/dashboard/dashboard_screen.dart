import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/aggregate_provider.dart';
import '../../widgets/total_progress_ring.dart';
import '../../widgets/goal_summary_card.dart';
import '../goals/goal_detail_screen.dart';
import '../goals/all_goals_screen.dart';

// ─────────────────────────────────────────────────────────
// DashboardScreen  (PRD §5.2)
//
// - App bar: 'MoneyByte' + notification bell (v2 placeholder)
// - Time-based greeting
// - TotalProgressRing (centred, large, with glow)
// - Recovery Mode Banner (shown when overdue > 0)
// - 'Your Goals' section + 'See all' link
// - Horizontal scrollable GoalSummaryCard row
// ─────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Saver';
    if (hour < 17) return 'Good afternoon, Saver';
    return 'Good evening, Saver';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync  = ref.watch(goalsProvider);
    final aggregate   = ref.watch(aggregateProvider);

    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Money',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorTextPrimary,
                ),
              ),
              TextSpan(
                text: 'Byte',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorNeonGreen,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Notification bell — v2 placeholder
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppTheme.colorTextSecondary,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming in v2'),
                ),
              );
            },
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.colorNeonGreen,
          ),
        ),
        error: (e, _) => const Center(
          child: Text('Error loading goals', style: AppTheme.bodyMedium),
        ),
        data: (goals) => _DashboardBody(
          goals: goals,
          aggregate: aggregate,
          greeting: _greeting(),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.goals,
    required this.aggregate,
    required this.greeting,
  });

  final List<Goal> goals;
  final AggregateData aggregate;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  greeting,
                  style: AppTheme.bodyMedium.copyWith(
                    fontSize: 20,
                    color: const Color(0xFFB0B8C8),
                  ),
                ),
                const SizedBox(height: 24),

                // Total Progress Ring — centred
                const Center(child: TotalProgressRing()),
                const SizedBox(height: 20),

                // Recovery Mode Banner (shown when ≥1 goal is overdue)
                if (aggregate.overdueCount > 0)
                  _RecoveryBanner(overdueCount: aggregate.overdueCount),

                const SizedBox(height: 24),

                // Section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Goals', style: AppTheme.headlineMedium.copyWith(fontSize: 20)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AllGoalsScreen(),
                          ),
                        );
                      },
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Horizontal scrollable goals row
        SliverToBoxAdapter(
          child: goals.isEmpty
              ? _EmptyGoalsHint()
              : SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: goals.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final goal = goals[i];
                      return GoalSummaryCard(
                        goal: goal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GoalDetailScreen(goalId: goal.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Recovery Mode Banner (PRD §5.2) ──────────────────────
class _RecoveryBanner extends StatelessWidget {
  const _RecoveryBanner({required this.overdueCount});
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.colorRecoveryAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.colorRecoveryAmber.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            color: AppTheme.colorRecoveryAmber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$overdueCount goal${overdueCount == 1 ? '' : 's'} need'
              '${overdueCount == 1 ? 's' : ''} your attention. Tap to view.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.colorRecoveryAmber,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.colorRecoveryAmber,
          ),
        ],
      ),
    );
  }
}

// ── Empty state hint (when no goals exist) ───────────────
class _EmptyGoalsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.savings_outlined,
            color: AppTheme.colorTextSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Add your first goal to get started!',
            style: AppTheme.bodyMedium.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tap the ',
                style: AppTheme.bodyMedium,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.colorNeonGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppTheme.colorNeonGreen,
                  size: 16,
                ),
              ),
              const Text(
                ' button below',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
