// lib/providers/transactions_provider.dart
// NEW FILE — StateNotifier that starts with hardcoded SpendingSimulator data
// and allows adding / deleting transactions in memory for demo purposes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/spending_simulator.dart';

class TransactionsNotifier
    extends StateNotifier<List<SimulatedTransaction>> {
  TransactionsNotifier() : super(SpendingSimulator.generate());

  /// Add a new transaction (appears immediately in BehaviorReport)
  void addTransaction({
    required String merchant,
    required String category,
    required double amount,
    required String emoji,
  }) {
    final id = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final txn = SimulatedTransaction(
      id: id,
      merchant: merchant,
      category: category,
      amount: amount,
      date: DateTime.now(),
      emoji: emoji,
    );
    state = [...state, txn];
  }

  /// Delete a transaction by id
  void deleteTransaction(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  /// Reset back to the original hardcoded dataset
  void reset() {
    state = SpendingSimulator.generate();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<SimulatedTransaction>>(
  (ref) => TransactionsNotifier(),
);