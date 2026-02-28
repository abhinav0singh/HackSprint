import '../../providers/goal_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/goal_model.dart';
import '../../home_widget/ring_widget_provider.dart';

// ─────────────────────────────────────────────────────────
// AddEditGoalScreen  (PRD §5.5)
//
// Fields:
//   - Goal Name (max 40 chars)
//   - Target Amount (INR numeric, min 1)
//   - Current Saved (INR, default 0)
//   - Target Date (optional date picker; must be > today)
//   - Category Icon (12-option grid)
//   - Accent Color (8 swatches)
//
// IMPORTANT: No monthly saving amount field exists anywhere
//            in this screen (Issue #1 - locked savings philosophy).
//
// Save button disabled until title + targetAmount are filled.
// ─────────────────────────────────────────────────────────

class AddEditGoalScreen extends ConsumerStatefulWidget {
  const AddEditGoalScreen({super.key, this.goal});

  /// null = Add mode, non-null = Edit mode
  final Goal? goal;

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _targetCtrl;
  late TextEditingController _savedCtrl;

  late String _selectedIcon;
  late String _selectedAccent;
  DateTime? _targetDate;
  bool _saving = false;

  bool get _isEditMode => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _titleCtrl  = TextEditingController(text: g?.title ?? '');
    _targetCtrl = TextEditingController(
      text: g != null ? g.targetAmount.toInt().toString() : '',
    );
    _savedCtrl  = TextEditingController(
      text: g != null ? g.currentSaved.toInt().toString() : '0',
    );
    _selectedIcon   = g?.iconPath ?? kIconList.first;
    _selectedAccent = g?.accentColorHex ?? kAccentSwatches.first;
    _targetDate = g?.targetDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _savedCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleCtrl.text.trim().isNotEmpty &&
      double.tryParse(_targetCtrl.text.trim()) != null &&
      (double.tryParse(_targetCtrl.text.trim()) ?? 0) >= 1;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final storage = ref.read(storageServiceProvider);
      final title    = _titleCtrl.text.trim();
      final target   = double.parse(_targetCtrl.text.trim());
      final saved    = double.tryParse(_savedCtrl.text.trim()) ?? 0.0;

      if (_isEditMode) {
        await storage.updateGoal(
          id: widget.goal!.id,
          title: title,
          targetAmount: target,
          iconPath: _selectedIcon,
          accentColorHex: _selectedAccent,
          targetDate: _targetDate,
        );
      } else {
        await storage.createGoal(
          title: title,
          targetAmount: target,
          currentSaved: saved.clamp(0, target),
          iconPath: _selectedIcon,
          accentColorHex: _selectedAccent,
          targetDate: _targetDate,
        );
      }

      await syncHomeWidget(ref);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goal: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)), // must be > today
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.colorNeonGreen,
            surface: AppTheme.colorSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Goal' : 'New Goal'),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Goal Name ─────────────────────────────────
            const _SectionLabel('Goal Name'),
            TextFormField(
              controller: _titleCtrl,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.colorTextPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. New Laptop',
                counterStyle: TextStyle(color: AppTheme.colorTextSecondary),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Goal name is required (max 40 chars)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Target Amount ─────────────────────────────
            const _SectionLabel('Target Amount (INR)'),
            TextFormField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.colorTextPrimary,
              ),
              decoration: const InputDecoration(
                prefixText: 'INR ',
                hintText: '10000',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Target amount is required';
                }
                final amount = double.tryParse(v.trim());
                if (amount == null || amount < 1) {
                  return 'Target must be between INR 1 and INR 9,99,99,999';
                }
                if (amount > 999999999) {
                  return 'Target must be between INR 1 and INR 9,99,99,999';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Current Saved (add mode only) ─────────────
            if (!_isEditMode) ...[
              const _SectionLabel('Already Saved (optional)'),
              TextFormField(
                controller: _savedCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.colorTextPrimary,
                ),
                decoration: const InputDecoration(
                  prefixText: 'INR ',
                  hintText: '0',
                ),
                validator: (v) {
                  final saved  = double.tryParse(v?.trim() ?? '') ?? 0.0;
                  final target = double.tryParse(_targetCtrl.text.trim()) ?? 0.0;
                  if (saved < 0) return 'Amount cannot be negative';
                  if (target > 0 && saved > target) {
                    return 'Amount exceeds goal. You need ${formatInr(target - saved)} more.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],

            // ── Target Date ───────────────────────────────
            const _SectionLabel('Target Date (optional)'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colorSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A3F4E)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppTheme.colorTextSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _targetDate != null
                            ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                            : 'No deadline (optional)',
                        style: AppTheme.bodyMedium.copyWith(
                          color: _targetDate != null
                              ? AppTheme.colorTextPrimary
                              : AppTheme.colorTextSecondary,
                        ),
                      ),
                    ),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: const Icon(
                          Icons.close,
                          color: AppTheme.colorTextSecondary,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Category Icon grid (12 icons) ─────────────
            const _SectionLabel('Category'),
            GridView.count(
              crossAxisCount: 6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: kIconList.asMap().entries.map((entry) {
                final path     = entry.value;
                final selected = path == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = path),
                  child: Tooltip(
                    message: kIconLabels[entry.key],
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? hexToColor(_selectedAccent).withOpacity(0.2)
                            : AppTheme.colorSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? hexToColor(_selectedAccent)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: SvgPicture.asset(
                        path,
                        colorFilter: ColorFilter.mode(
                          selected
                              ? hexToColor(_selectedAccent)
                              : AppTheme.colorTextSecondary,
                          BlendMode.srcIn,
                        ),
                        placeholderBuilder: (_) => Icon(
                          Icons.star,
                          color: selected
                              ? hexToColor(_selectedAccent)
                              : AppTheme.colorTextSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Accent Color swatches (8) ─────────────────
            const _SectionLabel('Accent Color'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kAccentSwatches.map((hex) {
                final color    = hexToColor(hex);
                final selected = hex == _selectedAccent;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAccent = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: AppTheme.colorTextPrimary,
                              width: 3,
                            )
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 18,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // ── Save button ───────────────────────────────
            ElevatedButton(
              onPressed: (_canSave && !_saving) ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.colorBackground,
                      ),
                    )
                  : Text(_isEditMode ? 'Save Changes' : 'Create Goal'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.colorTextSecondary,
        ),
      ),
    );
  }
}
