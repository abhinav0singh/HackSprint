import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../providers/aggregate_provider.dart';
import '../providers/goal_provider.dart';

// ─────────────────────────────────────────────────────────
// homeWidgetSyncProvider  (PRD §4.2, §5.8, Fix #16)
//
// Watches aggregateProvider and writes FULL snapshot to
// SharedPreferences, then triggers platform widget refresh.
//
// Android: AppWidgetManager — instant refresh.
// iOS:     WidgetCenter.reloadAllTimelines() — WidgetKit-budgeted,
//          NOT guaranteed instant. (Issue #5 resolved)
//
// Widget snapshot keys (Fix #16 — future-proof):
//   totalPercent  — 0.0 to 1.0
//   totalSaved    — INR double
//   totalTarget   — INR double
//   goalCount     — int
//   updatedAt     — ISO-8601 string
// ─────────────────────────────────────────────────────────

/// Call this after every Isar write to keep the home widget fresh.
Future<void> syncHomeWidget(WidgetRef ref) async {
  final aggregate = ref.read(aggregateProvider);
  final goals = ref.read(goalsProvider).value ?? [];

  final snapshot = jsonEncode({
    'totalPercent': aggregate.totalPercent,
    'totalSaved':   aggregate.totalSaved,
    'totalTarget':  aggregate.totalTarget,
    'goalCount':    goals.length,
    'updatedAt':    DateTime.now().toIso8601String(),
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefsWidgetSnapshot, snapshot);
    await HomeWidget.saveWidgetData<String>('snapshot', snapshot);
    await HomeWidget.updateWidget(
      androidName: 'MoneyByteWidgetProvider',
      iOSName: 'MoneyByteWidget',
    );
  } catch (_) {
    // Widget provider not registered yet — safe to ignore until
    // the Android widget is added to the home screen.
  }
}

/// Standalone (non-Riverpod) sync — used from StorageService
/// contexts where WidgetRef is not available.
Future<void> syncHomeWidgetData({
  required double totalPercent,
  required double totalSaved,
  required double totalTarget,
  required int goalCount,
}) async {
  final snapshot = jsonEncode({
    'totalPercent': totalPercent,
    'totalSaved':   totalSaved,
    'totalTarget':  totalTarget,
    'goalCount':    goalCount,
    'updatedAt':    DateTime.now().toIso8601String(),
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefsWidgetSnapshot, snapshot);
    await HomeWidget.saveWidgetData<String>('snapshot', snapshot);
    await HomeWidget.updateWidget(
      androidName: 'MoneyByteWidgetProvider',
      iOSName: 'MoneyByteWidget',
    );
  } catch (_) {
    // Widget provider not yet registered — safe to ignore.
  }
}
