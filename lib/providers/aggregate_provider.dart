import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'goal_provider.dart';
import '../models/goal_model.dart';

// ─────────────────────────────────────────────────────────
// Aggregate Providers  (PRD §3.4 — Philosophy Locked)
//
// Ring = sum(currentSaved) / sum(targetAmount)  [money-based]
// Issue #3 resolved: money-based, NOT goal-count average.
// Issue #2 fix: guarded against empty list + zero totalTarget.
// ─────────────────────────────────────────────────────────

class AggregateData {
  const AggregateData({
    required this.totalPercent,
    required this.totalSaved,
    required this.totalTarget,
    required this.goalCount,
    required this.overdueCount,
  });

  final double totalPercent;
  final double totalSaved;
  final double totalTarget;
  final int goalCount;
  final int overdueCount;
}

final aggregateProvider = Provider<AggregateData>((ref) {
  final goalsAsync = ref.watch(goalsProvider);

  return goalsAsync.when(
    data: (goals) => _compute(goals),
    loading: () => const AggregateData(
      totalPercent: 0.0,
      totalSaved: 0.0,
      totalTarget: 0.0,
      goalCount: 0,
      overdueCount: 0,
    ),
    error: (_, __) => const AggregateData(
      totalPercent: 0.0,
      totalSaved: 0.0,
      totalTarget: 0.0,
      goalCount: 0,
      overdueCount: 0,
    ),
  );
});

AggregateData _compute(List<Goal> goals) {
  final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
  final totalSaved  = goals.fold(0.0, (s, g) => s + g.currentSaved);
  final overdueCount = goals.where((g) => g.isOverdue).length;

  // Guard: empty list or zero total → 0.0 (Issue #2 + Issue #3)
  final percent = totalTarget == 0
      ? 0.0
      : (totalSaved / totalTarget).clamp(0.0, 1.0);

  return AggregateData(
    totalPercent: percent,
    totalSaved: totalSaved,
    totalTarget: totalTarget,
    goalCount: goals.length,
    overdueCount: overdueCount,
  );
}

/// Convenience provider — just the double for the ring widget.
final totalPercentProvider = Provider<double>(
  (ref) => ref.watch(aggregateProvider).totalPercent,
);
