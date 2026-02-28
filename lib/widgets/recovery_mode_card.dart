import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/goal_model.dart';
import '../providers/goal_provider.dart';

// ─────────────────────────────────────────────────────────
// RecoveryModeCard  (PRD §7.3)
//
// Appears on GoalDetailScreen when isOverdue == true.
// Coach-not-punish tone. Amber left-border. Never red.
//
// Contents:
//   - Coach copy (long form, PRD §7.3)
//   - Horizon picker: 1 / 3 / 6 months (default: 3)
//   - Recovery monthly suggestion amount (Fix #12 guarded)
//   - CTA: 'Update Target Date' + 'Keep Going'
// ─────────────────────────────────────────────────────────

class RecoveryModeCard extends ConsumerStatefulWidget {
  const RecoveryModeCard({
    super.key,
    required this.goal,
    this.onDismissed,
  });

  final Goal goal;
  final VoidCallback? onDismissed;

  @override
  ConsumerState<RecoveryModeCard> createState() => _RecoveryModeCardState();
}

class _RecoveryModeCardState extends ConsumerState<RecoveryModeCard> {
  int _horizonMonths = 3; // default per PRD §7.3
  bool _dismissed = false;

  // Horizon options
  static const List<int> _horizons = [1, 3, 6];

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final goal = widget.goal;
    final pct = (goal.progressPercent * 100).round();
    final suggestion = goal.recoveryMonthlySuggestion(_horizonMonths);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(
            color: AppTheme.colorRecoveryAmber,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colorRecoveryAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🔁 Recovery Mode',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.colorRecoveryAmber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Coach copy (long form — PRD §7.3)
          Text(
            'You are $pct% of the way there. You have already saved '
            '${formatInr(goal.currentSaved)}. Want to set a new target date?',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.colorTextPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Horizon picker
          Text(
            'Finish in:',
            style: AppTheme.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.colorTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _horizons.map((months) {
              final selected = months == _horizonMonths;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _horizonMonths = months),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.colorRecoveryAmber
                          : AppTheme.colorSurfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.colorRecoveryAmber
                            : AppTheme.colorDivider,
                      ),
                    ),
                    child: Text(
                      '$months mo',
                      style: AppTheme.labelSmall.copyWith(
                        color: selected
                            ? AppTheme.colorBackground
                            : AppTheme.colorTextSecondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Suggestion amount
          suggestion > 0
              ? Text(
                  'Save ${formatInr(suggestion)}/month to finish in '
                  '$_horizonMonths month${_horizonMonths == 1 ? '' : 's'}.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.colorRecoveryAmber,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(
                  'You have already saved enough!',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.colorNeonGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          const SizedBox(height: 20),

          // CTAs
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.colorRecoveryAmber,
                    side: const BorderSide(
                      color: AppTheme.colorRecoveryAmber,
                    ),
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => _pickNewDate(context),
                  child: const Text('Update Target Date'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.colorTextSecondary,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () {
                    // Dismiss for this session only — does NOT disable
                    // Recovery Mode permanently (PRD §7.3).
                    setState(() => _dismissed = true);
                    widget.onDismissed?.call();
                  },
                  child: const Text('Keep Going'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickNewDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.colorRecoveryAmber,
            surface: AppTheme.colorSurface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    final storage = ref.read(storageServiceProvider);
    await storage.updateTargetDate(widget.goal.id, picked);
  }
}


