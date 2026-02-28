import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/storage_service.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/add_money_bottom_sheet.dart';
import '../../widgets/recovery_mode_card.dart';
import '../../home_widget/ring_widget_provider.dart';
import 'add_edit_goal_screen.dart';

// ─────────────────────────────────────────────────────────
// GoalDetailScreen  (PRD §5.4)
//
// Layout:
//   - Large icon + title
//   - Neon LinearPercentIndicator (full width, height 14)
//   - INR currentSaved / INR targetAmount
//   - Status card: 'X days remaining' (green) OR 'X days overdue' (amber)
//   - Monthly suggestion card (when targetDate set, not overdue, not completed)
//   - RecoveryModeCard (when isOverdue == true)
//   - '+ Add Money' button
//   - 'Undo Last Deposit' (visible per canUndo conditions, Fix #11)
//   - 'Edit Goal' + 'Delete Goal' (red)
//
// ConfettiController:
//   - Lives in THIS State (Fix #15 — NEVER in provider or model)
//   - dispose() called in this State.dispose()
// ─────────────────────────────────────────────────────────

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({
    super.key,
    required this.goalId,
    this.openEditOnLoad = false,
  });

  final int goalId;
  final bool openEditOnLoad;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  // ARCHITECTURE RULE (Fix #15):
  // ConfettiController lives here — UI layer only.
  // Never in provider, model, or StorageService.
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    if (widget.openEditOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openEdit());
    }
  }

  @override
  void dispose() {
    _confettiController.dispose(); // REQUIRED (Issue #6)
    super.dispose();
  }

  Future<void> _openEdit() async {
    final goal = ref.read(goalsProvider).value?.firstWhere(
          (g) => g.id == widget.goalId,
          orElse: () => throw StateError('Goal not found'),
        );
    if (goal == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditGoalScreen(goal: goal),
      ),
    );
  }

  Future<void> _addMoney(Goal goal) async {
    final wasCompleted = await showAddMoneyBottomSheet(context, ref, goal);

    if (wasCompleted && mounted) {
      // Goal Completion Flow (PRD §7.1 Flow C)
      _confettiController.play();
    }
  }

  Future<void> _undoLastDeposit(Goal goal) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Undo Last Deposit?'),
        content: Text(
          'Remove ${formatInr(goal.lastModifiedAmount)} from "${goal.title}"?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final storage = ref.read(storageServiceProvider);
    final success = await storage.undoLastDeposit(goal.id);

    if (!mounted) return;

    if (success) {
      await syncHomeWidget(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${formatInr(goal.lastModifiedAmount)} removed from "${goal.title}"',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot undo this deposit.')),
      );
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text(
          'Delete "${goal.title}"? This cannot be undone.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.colorError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(storageServiceProvider).deleteGoal(goal.id);
    await syncHomeWidget(ref);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return goalsAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.colorNeonGreen),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Error loading goal', style: AppTheme.bodyMedium),
        ),
      ),
      data: (goals) {
        final goal = goals.cast<Goal?>().firstWhere(
              (g) => g?.id == widget.goalId,
              orElse: () => null,
            );

        if (goal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Goal not found', style: AppTheme.bodyMedium),
            ),
          );
        }

        return _GoalDetailBody(
          goal: goal,
          confettiController: _confettiController,
          onAddMoney: () => _addMoney(goal),
          onUndo: () => _undoLastDeposit(goal),
          onEdit: _openEdit,
          onDelete: () => _deleteGoal(goal),
        );
      },
    );
  }
}

// ── Detail body ───────────────────────────────────────────
class _GoalDetailBody extends StatelessWidget {
  const _GoalDetailBody({
    required this.goal,
    required this.confettiController,
    required this.onAddMoney,
    required this.onUndo,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final ConfettiController confettiController;
  final VoidCallback onAddMoney;
  final VoidCallback onUndo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accentColor = hexToColor(goal.accentColorHex);
    final canUndo = StorageService.canUndo(goal);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.colorBackground,
          appBar: AppBar(
            title: Text(
              goal.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon + title ──────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: SvgPicture.asset(
                          goal.iconPath,
                          colorFilter: ColorFilter.mode(
                            accentColor,
                            BlendMode.srcIn,
                          ),
                          placeholderBuilder: (_) => Icon(
                            Icons.star,
                            color: accentColor,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(goal.title, style: AppTheme.headlineMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Progress bar (full width, height 14) ─
                LinearPercentIndicator(
                  lineHeight: 14.0,
                  percent: goal.progressPercent,
                  progressColor: goal.isOverdue
                      ? AppTheme.colorRecoveryAmber
                      : accentColor,
                  backgroundColor: AppTheme.colorSurface,
                  barRadius: const Radius.circular(8),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 1000,
                ),
                const SizedBox(height: 16),

                // ── Saved / Target amounts ────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatInr(goal.currentSaved),
                          style: AppTheme.headlineMedium.copyWith(
                            color: goal.isCompleted
                                ? AppTheme.colorNeonGreen
                                : AppTheme.colorTextPrimary,
                          ),
                        ),
                        const Text('saved', style: AppTheme.labelSmall),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatInr(goal.targetAmount),
                          style: AppTheme.titleLarge,
                        ),
                        const Text('target', style: AppTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Status card ───────────────────────────
                _StatusCard(goal: goal),
                const SizedBox(height: 16),

                // ── Monthly suggestion (active+dated only) ─
                if (goal.monthlySavingsNeeded != null)
                  _MonthlySuggestionCard(amount: goal.monthlySavingsNeeded!),

                // ── RecoveryModeCard (overdue only) ───────
                if (goal.isOverdue) ...[
                  const SizedBox(height: 4),
                  RecoveryModeCard(goal: goal),
                ],

                const SizedBox(height: 28),

                // ── Add Money button ──────────────────────
                if (!goal.isCompleted)
                  ElevatedButton.icon(
                    onPressed: onAddMoney,
                    icon: const Icon(Icons.add),
                    label: const Text('+ Add Money'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goal.isOverdue
                          ? AppTheme.colorRecoveryAmber
                          : AppTheme.colorNeonGreen,
                      foregroundColor: AppTheme.colorBackground,
                    ),
                  ),

                // ── Undo Last Deposit ─────────────────────
                // Visible ONLY when canUndo conditions pass (Fix #11)
                if (canUndo) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onUndo,
                    icon: const Icon(Icons.undo, size: 18),
                    label: Text(
                      'Undo Last Deposit (${formatInr(goal.lastModifiedAmount)})',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.colorTextSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // ── Edit Goal ─────────────────────────────
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Goal'),
                ),
                const SizedBox(height: 12),

                // ── Delete Goal (red, destructive) ────────
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Goal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.colorError,
                    side: const BorderSide(color: AppTheme.colorError),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // ── Confetti overlay (Flow C - Fix #15) ──────────
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            colors: const [
              AppTheme.colorNeonGreen,
              AppTheme.colorRecoveryAmber,
              Color(0xFF00B0FF),
              Color(0xFFFFD600),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Status card ───────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    if (goal.isCompleted) {
      return _chip(
        icon: Icons.check_circle,
        label: 'Goal Completed! 🎉',
        color: AppTheme.colorNeonGreen,
      );
    }

    if (goal.isOverdue) {
      final days = (goal.daysRemaining ?? 0).abs();
      return _chip(
        icon: Icons.warning_amber_outlined,
        label: '$days day${days == 1 ? '' : 's'} overdue',
        color: AppTheme.colorRecoveryAmber,
      );
    }

    final days = goal.daysRemaining;
    if (days != null) {
      return _chip(
        icon: Icons.calendar_today_outlined,
        label: '$days day${days == 1 ? '' : 's'} remaining',
        color: AppTheme.colorNeonGreen,
      );
    }

    return _chip(
      icon: Icons.all_inclusive,
      label: 'No deadline set',
      color: AppTheme.colorTextSecondary,
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monthly suggestion card ───────────────────────────────
class _MonthlySuggestionCard extends StatelessWidget {
  const _MonthlySuggestionCard({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.colorRecoveryAmber.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up,
            color: AppTheme.colorRecoveryAmber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Save ${formatInr(amount)}/month to hit your target',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.colorTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
