import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/goal_model.dart';
import '../providers/goal_provider.dart';
import '../home_widget/ring_widget_provider.dart';

// ─────────────────────────────────────────────────────────
// AddMoneyBottomSheet  (PRD §5.6, Fix v1.1 Issue #4)
//
// On save:
//   currentSaved += amount
//   lastModifiedAmount = amount   ← enables Undo Last Deposit
//   updatedAt = now()
//
// If new currentSaved >= targetAmount: returns willComplete=true
// so caller can trigger confetti flow.
// ─────────────────────────────────────────────────────────

/// Shows the Add Money bottom sheet.
/// Returns true if the goal was completed by this addition.
Future<bool> showAddMoneyBottomSheet(
  BuildContext context,
  WidgetRef ref,
  Goal goal,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.colorSurfaceAlt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddMoneySheet(goal: goal, ref: ref),
  );
  return result ?? false;
}

class _AddMoneySheet extends ConsumerStatefulWidget {
  const _AddMoneySheet({required this.goal, required this.ref});
  final Goal goal;
  final WidgetRef ref;

  @override
  ConsumerState<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends ConsumerState<_AddMoneySheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _errorText;

  double get _remaining => widget.goal.targetAmount - widget.goal.currentSaved;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an amount';
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) return 'Enter a valid amount greater than 0';
    if (amount > _remaining) {
      return 'You need ${formatInr(_remaining)} more. '
          'Amount exceeds goal.';
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _errorText = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_controller.text.trim());

    setState(() => _loading = true);

    try {
      final storage = ref.read(storageServiceProvider);
      final updated = await storage.addMoney(widget.goal.id, amount);

      // Sync home widget
      await syncHomeWidget(widget.ref);

      if (!mounted) return;
      Navigator.of(context).pop(updated?.isCompleted ?? false);
    } catch (e) {
      setState(() {
        _loading = false;
        _errorText = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.colorDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Add to ${widget.goal.title}',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '${formatInr(_remaining)} remaining to goal',
              style: AppTheme.labelSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.colorTextPrimary,
              ),
              decoration: InputDecoration(
                prefixText: 'INR ',
                prefixStyle: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.colorTextSecondary,
                ),
                hintText: '0',
                hintStyle: AppTheme.titleLarge.copyWith(
                  color: AppTheme.colorTextSecondary,
                ),
              ),
              validator: _validate,
              onFieldSubmitted: (_) => _save(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.colorError,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.colorBackground,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}


