// lib/providers/behavior_provider.dart
// UPDATED — behaviorReportProvider now watches transactionsProvider so any
// add/delete instantly recalculates the BehaviorReport and updates all UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/behavioral_engine.dart';
import 'transactions_provider.dart';

/// Controls which tab ShellScreen shows (0=Dashboard, 1=Goals, 2=Analytics).
final shellTabIndexProvider = StateProvider<int>((ref) => 0);

/// Recalculates every time the transaction list changes.
final behaviorReportProvider = Provider<BehaviorReport>((ref) {
  final transactions = ref.watch(transactionsProvider); // ← reactive
  final report = BehavioralEngine.analyze(transactions);

  // Write flags for Android home widget (fire-and-forget)
  _writeWidgetData(report.isAtRisk, report.savingsRate);

  return report;
});

Future<void> _writeWidgetData(bool isAtRisk, double savingsRate) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('moneybyte_behavior_alert', isAtRisk);
    await prefs.setDouble('moneybyte_savings_rate', savingsRate);
  } catch (_) {}
}