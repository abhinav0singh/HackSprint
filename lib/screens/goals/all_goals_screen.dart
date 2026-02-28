import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/goal_summary_card.dart';
import 'goal_detail_screen.dart';

// ─────────────────────────────────────────────────────────
// AllGoalsScreen  (PRD §5.3)
//
// Three tabs: Active | Overdue | Completed
// Active:    isCompleted==false AND isOverdue==false, by targetDate asc
// Overdue:   isOverdue==true, amber-tinted cards
// Completed: isCompleted==true, green checkmark badge
//
// Long-press → bottom sheet: Edit / Delete
// ─────────────────────────────────────────────────────────

class AllGoalsScreen extends ConsumerStatefulWidget {
  const AllGoalsScreen({super.key});

  @override
  ConsumerState<AllGoalsScreen> createState() => _AllGoalsScreenState();
}

class _AllGoalsScreenState extends ConsumerState<AllGoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active    = ref.watch(activeGoalsProvider);
    final overdue   = ref.watch(overdueGoalsProvider);
    final completed = ref.watch(completedGoalsProvider);

    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('All Goals'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.colorNeonGreen,
          unselectedLabelColor: AppTheme.colorTextSecondary,
          indicatorColor: AppTheme.colorNeonGreen,
          indicatorWeight: 2,
          tabs: [
            Tab(text: 'Active (${active.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Overdue',
                    style: TextStyle(
                      color: overdue.isEmpty
                          ? AppTheme.colorTextSecondary
                          : AppTheme.colorRecoveryAmber,
                    ),
                  ),
                  if (overdue.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.colorRecoveryAmber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${overdue.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Completed (${completed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GoalsList(
            goals: active,
            emptyText: 'No active goals.\nTap + to add one!',
          ),
          _GoalsList(
            goals: overdue,
            emptyText: 'No overdue goals.\nYou are on track!',
            emptyColor: AppTheme.colorNeonGreen,
          ),
          _GoalsList(
            goals: completed,
            emptyText: 'No completed goals yet.\nKeep saving!',
          ),
        ],
      ),
    );
  }
}

class _GoalsList extends ConsumerWidget {
  const _GoalsList({
    required this.goals,
    required this.emptyText,
    this.emptyColor,
  });

  final List<Goal> goals;
  final String emptyText;
  final Color? emptyColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goals.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: AppTheme.bodyMedium.copyWith(
            color: emptyColor ?? AppTheme.colorTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final goal = goals[i];
        return GoalSummaryCard(
          goal: goal,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GoalDetailScreen(goalId: goal.id),
            ),
          ),
          onLongPress: () => _showOptionsSheet(context, ref, goal),
        );
      },
    );
  }

  void _showOptionsSheet(BuildContext context, WidgetRef ref, dynamic goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.colorSurfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppTheme.colorNeonGreen,
              ),
              title: Text(
                'Edit',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.colorTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GoalDetailScreen(
                      goalId: goal.id,
                      openEditOnLoad: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppTheme.colorError,
              ),
              title: Text(
                'Delete',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.colorError,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, goal);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    dynamic goal,
  ) async {
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

    if (confirmed == true) {
      await ref.read(storageServiceProvider).deleteGoal(goal.id);
    }
  }
}
