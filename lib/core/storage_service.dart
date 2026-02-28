import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../models/goal_model.dart';

// ─────────────────────────────────────────────────────────
// StorageService  (PRD §4.1, §7.1, §7.2)
//
// Single access point for all Isar writes.
// Handles: create, update, delete, addMoney, undoLastDeposit.
// isOverdue is a PURE COMPUTED GETTER on Goal — never written here.
// ─────────────────────────────────────────────────────────

class StorageService {
  StorageService._(this._isar);

  final Isar _isar;

  static StorageService? _instance;

  /// Initialise Isar and return the singleton [StorageService].
  static Future<StorageService> init() async {
    if (_instance != null) return _instance!;

    final dir = await getApplicationDocumentsDirectory();

    final isar = await Isar.open(
      [GoalSchema],
      directory: dir.path,
      name: 'moneybyte_db',
    );

    _instance = StorageService._(isar);
    return _instance!;
  }

  Isar get isar => _isar;

  // ── Streams ──────────────────────────────────────────────

  /// Live stream of all goals.
  /// Sorting applied in goalsProvider, not here.
  Stream<List<Goal>> watchGoals() =>
      _isar.goals.where().watch(fireImmediately: true);

  // ── Read ─────────────────────────────────────────────────

  Future<List<Goal>> getAllGoals() => _isar.goals.where().findAll();

  Future<Goal?> getGoalById(Id id) => _isar.goals.get(id);

  // ── Create ───────────────────────────────────────────────

  /// Creates a new goal.
  /// [lastModifiedAmount] defaults to 0.0 for new goals (PRD §3.2).
  Future<void> createGoal({
    required String title,
    required double targetAmount,
    required double currentSaved,
    required String iconPath,
    required String accentColorHex,
    DateTime? targetDate,
  }) async {
    final now = DateTime.now();
    final goal = Goal()
      ..uuid = const Uuid().v4()
      ..title = title
      ..targetAmount = targetAmount
      ..currentSaved = currentSaved.clamp(0.0, targetAmount)
      ..iconPath = iconPath
      ..accentColorHex = accentColorHex
      ..targetDate = targetDate
      ..isCompleted = currentSaved >= targetAmount
      ..lastModifiedAmount = 0.0
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.goals.put(goal);
    });
  }

  // ── Update ───────────────────────────────────────────────

  /// Updates an existing goal's editable fields.
  /// Does NOT touch currentSaved, lastModifiedAmount, uuid, or createdAt.
  Future<void> updateGoal({
    required Id id,
    required String title,
    required double targetAmount,
    required String iconPath,
    required String accentColorHex,
    DateTime? targetDate,
  }) async {
    await _isar.writeTxn(() async {
      final goal = await _isar.goals.get(id);
      if (goal == null) return;

      goal
        ..title = title
        ..targetAmount = targetAmount
        ..iconPath = iconPath
        ..accentColorHex = accentColorHex
        ..targetDate = targetDate
        ..isCompleted = goal.currentSaved >= targetAmount
        ..updatedAt = DateTime.now();

      await _isar.goals.put(goal);
    });
  }

  // ── Add Money ────────────────────────────────────────────

  Future<Goal?> addMoney(Id goalId, double amount) async {
    Goal? updated;
    await _isar.writeTxn(() async {
      final goal = await _isar.goals.get(goalId);
      if (goal == null) return;

      final newSaved =
          (goal.currentSaved + amount).clamp(0.0, goal.targetAmount);

      goal
        ..currentSaved = newSaved
        ..lastModifiedAmount = amount
        ..isCompleted = newSaved >= goal.targetAmount
        ..updatedAt = DateTime.now();

      await _isar.goals.put(goal);
      updated = goal;
    });
    return updated;
  }

  // ── Undo Last Deposit ────────────────────────────────────

  Future<bool> undoLastDeposit(Id goalId) async {
    bool success = false;
    await _isar.writeTxn(() async {
      final goal = await _isar.goals.get(goalId);
      if (goal == null) return;
      if (!canUndo(goal)) return;

      goal
        ..currentSaved -= goal.lastModifiedAmount
        ..lastModifiedAmount = 0.0
        ..isCompleted = false
        ..updatedAt = DateTime.now();

      await _isar.goals.put(goal);
      success = true;
    });
    return success;
  }

  // ── Update Target Date ──────────────────────────────────

  Future<void> updateTargetDate(Id goalId, DateTime? newDate) async {
    await _isar.writeTxn(() async {
      final goal = await _isar.goals.get(goalId);
      if (goal == null) return;

      goal
        ..targetDate = newDate
        ..updatedAt = DateTime.now();

      await _isar.goals.put(goal);
    });
  }

  // ── Delete ───────────────────────────────────────────────

  Future<void> deleteGoal(Id goalId) async {
    await _isar.writeTxn(() async {
      await _isar.goals.delete(goalId);
    });
  }

  // ── canUndo guard (PRD §7.1, Fix #11) ───────────────────

  static bool canUndo(Goal g) {
    if (g.lastModifiedAmount <= 0) return false;
    if (g.isCompleted) return false;
    if (g.currentSaved < g.lastModifiedAmount) return false;
    return true;
  }
}

