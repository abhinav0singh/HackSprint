import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage_service.dart';
import '../models/goal_model.dart';

// ─────────────────────────────────────────────────────────
// Providers  (PRD §4.2 Provider Dependency Map)
// ─────────────────────────────────────────────────────────

// ── storageServiceProvider ───────────────────────────────
/// Isar singleton. All writes go through here.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'storageServiceProvider must be overridden in ProviderScope overrides.',
  );
});

// ── goalsProvider ────────────────────────────────────────
/// StreamProvider<List<Goal>> that watches the Isar collection.
/// Emits sorted list on any change.
///
/// Sort order (PRD §4.2):
///   1. isOverdue == true  (amber)          — most overdue first
///   2. Active, sorted by targetDate asc    — no deadline last
///   3. Completed                           — bottom
///
/// isOverdue is a pure computed getter — no DB writes needed.
final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final storage = ref.watch(storageServiceProvider);

  return storage.watchGoals().map((goals) {
    final overdue    = goals.where((g) => g.isOverdue).toList();
    final active     = goals.where((g) => !g.isOverdue && !g.isCompleted).toList();
    final completed  = goals.where((g) => g.isCompleted).toList();

    // Most overdue first (smallest/most-negative daysRemaining first)
    overdue.sort((a, b) {
      final da = a.daysRemaining ?? 0;
      final db = b.daysRemaining ?? 0;
      return da.compareTo(db);
    });

    // Active: targetDate ascending; no-deadline goals go last
    active.sort((a, b) {
      if (a.targetDate == null && b.targetDate == null) return 0;
      if (a.targetDate == null) return 1;
      if (b.targetDate == null) return -1;
      return a.targetDate!.compareTo(b.targetDate!);
    });

    return [...overdue, ...active, ...completed];
  });
});

// ── Filtered views (used by AllGoalsScreen tabs) ─────────
final activeGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).value?.where(
    (g) => !g.isCompleted && !g.isOverdue,
  ).toList() ?? [];
});

final overdueGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).value?.where(
    (g) => g.isOverdue,
  ).toList() ?? [];
});

final completedGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).value?.where(
    (g) => g.isCompleted,
  ).toList() ?? [];
});
