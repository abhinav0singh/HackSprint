import 'package:isar/isar.dart';

part 'goal_model.g.dart';

// ─────────────────────────────────────────────────────────
// Goal  —  Isar @collection schema  (PRD §3.1, v1.2 Final)
//
// DUAL ID RATIONALE (Issue #7):
//   id   — Isar-managed int. Used for all DB queries/writes.
//   uuid — Stable UUID v4. Used for home widget deep-links
//          and external references without coupling to Isar.
//
// isOverdue is NOT stored in DB (Fix #10):
//   Stored stale state risks timing bugs and unnecessary writes.
//   It is a pure computed getter recalculated on every access.
// ─────────────────────────────────────────────────────────

@collection
class Goal {
  // ── Persistence ─────────────────────────────────────────
  Id id = Isar.autoIncrement;

  /// UUID v4 — used for widget deep-links and external refs.
  late String uuid;

  // ── Core Fields ──────────────────────────────────────────
  late String title;           // max 40 chars
  late double targetAmount;    // min 1.0 (INR)
  late double currentSaved;    // >= 0.0
  late String iconPath;        // e.g. 'assets/icons/laptop.svg'
  late String accentColorHex;  // e.g. '00E676' (no # prefix)
  DateTime? targetDate;        // nullable - optional deadline

  // ── Status ───────────────────────────────────────────────
  late bool isCompleted; // true when currentSaved >= targetAmount

  // isOverdue is NOT stored here. Pure computed getter below.

  // ── Audit Safety (Issue #4) ──────────────────────────────
  /// Amount delta of the last Add Money operation.
  /// Enables single-level Undo Last Deposit (v1.1).
  /// Defaults to 0.0 on creation. Reset to 0.0 after undo.
  late double lastModifiedAmount;

  // ── Timestamps ───────────────────────────────────────────
  late DateTime createdAt;
  late DateTime updatedAt;

  // ═══════════════════════════════════════════════════════
  // COMPUTED / DERIVED VALUES  (PRD §3.3, v1.1 + v1.2)
  // ═══════════════════════════════════════════════════════

  /// Safe against division-by-zero and DB corruption (Issue #2).
  /// Returns 0.0 if targetAmount == 0. Clamped to [0, 1].
  double get progressPercent =>
      targetAmount == 0
          ? 0.0
          : (currentSaved / targetAmount).clamp(0.0, 1.0);

  /// Days remaining until targetDate.
  /// Negative = overdue. Null = no deadline.
  /// Recalculated on every widget rebuild (mid-session drift
  /// is an intentional MVP trade-off — Fix #13).
  int? get daysRemaining {
    if (targetDate == null) return null;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  /// Pure computed getter — NOT stored in DB (Fix #10).
  /// Reactive via Riverpod: no batch recompute, no writes.
  bool get isOverdue =>
      targetDate != null &&
      DateTime.now().isAfter(targetDate!) &&
      !isCompleted;

  /// App-calculated monthly savings needed (Option A, Issue #1).
  /// Returns null when: no targetDate, goal is overdue, or completed.
  /// In Recovery Mode use [recoveryMonthlySuggestion] instead.
  double? get monthlySavingsNeeded {
    if (targetDate == null || isCompleted || isOverdue) return null;
    final days = daysRemaining ?? 0;
    if (days <= 0) return null;
    return (targetAmount - currentSaved) / (days / 30.0);
  }

  /// Recovery Mode monthly suggestion (Issue #8, Fix #12).
  /// Guard added: remaining <= 0 returns 0.0. Result clamped >= 0.
  double recoveryMonthlySuggestion(int horizonMonths) {
    final remaining =
        (targetAmount - currentSaved).clamp(0.0, double.infinity);
    if (remaining <= 0) return 0.0;
    if (horizonMonths <= 0) return 0.0;
    return remaining / horizonMonths;
  }
}
