// lib/widgets/transactions_bottom_sheet.dart
// NEW FILE — Bottom sheet to add / delete simulated transactions for demo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/spending_simulator.dart';
import '../providers/transactions_provider.dart';

// Category metadata for the dropdown
const _categories = [
  _CatMeta(SpendingSimulator.kFood,          '🍕', 'Food & Delivery'),
  _CatMeta(SpendingSimulator.kEntertainment, '🎮', 'Entertainment'),
  _CatMeta(SpendingSimulator.kShopping,      '🛍️', 'Shopping'),
  _CatMeta(SpendingSimulator.kTransport,     '🚗', 'Transport'),
  _CatMeta(SpendingSimulator.kSavings,       '💰', 'Savings'),
];

class _CatMeta {
  final String key;
  final String emoji;
  final String label;
  const _CatMeta(this.key, this.emoji, this.label);
}

// ── Public helper to open the sheet ──────────────────────
void showTransactionsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12151C),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _TransactionsSheet(),
  );
}

// ── Sheet widget ─────────────────────────────────────────
class _TransactionsSheet extends ConsumerStatefulWidget {
  const _TransactionsSheet();

  @override
  ConsumerState<_TransactionsSheet> createState() => _TransactionsSheetState();
}

class _TransactionsSheetState extends ConsumerState<_TransactionsSheet> {
  bool _showAddForm = false;

  // Add-form controllers
  final _merchantCtrl = TextEditingController();
  final _amountCtrl   = TextEditingController();
  _CatMeta _selectedCat = _categories[0];

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submitAdd() {
    final merchant = _merchantCtrl.text.trim();
    final amount   = double.tryParse(_amountCtrl.text.trim());
    if (merchant.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid merchant and amount')),
      );
      return;
    }
    ref.read(transactionsProvider.notifier).addTransaction(
      merchant: merchant,
      category: _selectedCat.key,
      amount: amount,
      emoji: _selectedCat.emoji,
    );
    _merchantCtrl.clear();
    _amountCtrl.clear();
    setState(() => _showAddForm = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ₹${amount.toStringAsFixed(0)} · $merchant'),
        backgroundColor: const Color(0xFF00E676),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final bottomInset  = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF6B6F7A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: [
                  const Text(
                    '💸 Transactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Reset button
                  TextButton(
                    onPressed: () {
                      ref.read(transactionsProvider.notifier).reset();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transactions reset to default')),
                      );
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Color(0xFF6B6F7A), fontSize: 12),
                    ),
                  ),
                  // Add button
                  IconButton(
                    onPressed: () => setState(() => _showAddForm = !_showAddForm),
                    icon: Icon(
                      _showAddForm ? Icons.close : Icons.add_circle_outline,
                      color: const Color(0xFF00E676),
                    ),
                    tooltip: 'Add transaction',
                  ),
                ],
              ),
            ),

            // ── Add form (collapsible) ────────────────────
            if (_showAddForm)
              _AddTransactionForm(
                merchantCtrl: _merchantCtrl,
                amountCtrl: _amountCtrl,
                selectedCat: _selectedCat,
                onCatChanged: (cat) => setState(() => _selectedCat = cat!),
                onSubmit: _submitAdd,
              ),

            const Divider(color: Color(0xFF2A2D36), height: 1),

            // ── Transaction list ──────────────────────────
            Expanded(
              child: transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions',
                        style: TextStyle(color: Color(0xFF6B6F7A)),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: transactions.length,
                      itemBuilder: (_, i) {
                        // Show in reverse so newest additions appear at top
                        final txn = transactions[transactions.length - 1 - i];
                        return _TransactionTile(
                          txn: txn,
                          onDelete: () => ref
                              .read(transactionsProvider.notifier)
                              .deleteTransaction(txn.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add form widget ───────────────────────────────────────
class _AddTransactionForm extends StatelessWidget {
  const _AddTransactionForm({
    required this.merchantCtrl,
    required this.amountCtrl,
    required this.selectedCat,
    required this.onCatChanged,
    required this.onSubmit,
  });

  final TextEditingController merchantCtrl;
  final TextEditingController amountCtrl;
  final _CatMeta selectedCat;
  final ValueChanged<_CatMeta?> onCatChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Transaction',
            style: TextStyle(
              color: Color(0xFF00E676),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),

          // Merchant name
          TextField(
            controller: merchantCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDeco('Merchant (e.g. Zomato)'),
          ),
          const SizedBox(height: 8),

          // Amount
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDeco('Amount in ₹'),
          ),
          const SizedBox(height: 8),

          // Category dropdown
          DropdownButtonFormField<_CatMeta>(
            value: selectedCat,
            dropdownColor: const Color(0xFF2A2D36),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDeco('Category'),
            items: _categories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.emoji}  ${c.label}'),
                    ))
                .toList(),
            onChanged: onCatChanged,
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add Transaction',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B6F7A), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF12151C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      );
}

// ── Single transaction tile ───────────────────────────────
class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.txn, required this.onDelete});
  final SimulatedTransaction txn;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isUserAdded = txn.id.startsWith('usr_');
    return ListTile(
      dense: true,
      leading: Text(txn.emoji, style: const TextStyle(fontSize: 22)),
      title: Text(
        txn.merchant,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      subtitle: Text(
        txn.category,
        style: const TextStyle(color: Color(0xFF6B6F7A), fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${txn.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: isUserAdded
                  ? const Color(0xFF00E676)
                  : const Color(0xFFB0B3BA),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFFE53935),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}