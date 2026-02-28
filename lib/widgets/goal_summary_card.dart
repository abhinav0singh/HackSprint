import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/goal_model.dart';

// ─────────────────────────────────────────────────────────
// GoalSummaryCard  (PRD §6.3)
//
// Three visual states:
//   State 1: Active (normal)        — neon green accent
//   State 2: Overdue (Recovery Mode) — amber tint, amber bar
//   State 3: Completed              — 30% neon green wash
// ─────────────────────────────────────────────────────────

class GoalSummaryCard extends StatelessWidget {
  const GoalSummaryCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onLongPress,
  });

  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (goal.isCompleted) return _CompletedCard(goal: goal, onTap: onTap, onLongPress: onLongPress);
    if (goal.isOverdue)   return _OverdueCard(goal: goal, onTap: onTap, onLongPress: onLongPress);
    return _ActiveCard(goal: goal, onTap: onTap, onLongPress: onLongPress);
  }
}

// ── Shared card shell ─────────────────────────────────────
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.backgroundColor,
    required this.child,
    required this.goal,
    this.onTap,
    this.onLongPress,
  });

  final Color backgroundColor;
  final Widget child;
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}

// ── State 1: Active card ──────────────────────────────────
class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.goal, this.onTap, this.onLongPress});
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final accentColor = hexToColor(goal.accentColorHex);
    final days = goal.daysRemaining;
    final monthly = goal.monthlySavingsNeeded;

    return _CardShell(
      goal: goal,
      backgroundColor: AppTheme.colorSurface,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GoalIcon(iconPath: goal.iconPath, color: accentColor),
              const Spacer(),
              if (days != null)
                Text(
                  '$days day${days == 1 ? '' : 's'} left',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.colorNeonGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            goal.title,
            style: AppTheme.titleLarge.copyWith(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            formatInr(goal.currentSaved),
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.colorTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'of ${formatInr(goal.targetAmount)}',
            style: AppTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            lineHeight: 6.0,
            percent: goal.progressPercent,
            progressColor: accentColor,
            backgroundColor: AppTheme.colorSurfaceAlt,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 800,
          ),
          if (monthly != null) ...[
            const SizedBox(height: 8),
            _MonthlySuggestionChip(amount: monthly),
          ],
        ],
      ),
    );
  }
}

// ── State 2: Overdue / Recovery Mode card ────────────────
class _OverdueCard extends StatelessWidget {
  const _OverdueCard({required this.goal, this.onTap, this.onLongPress});
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    // Subtle amber tint: Color.lerp(#2A2D36, #FF9800, 0.08)
    final bg = Color.lerp(
      AppTheme.colorSurface,
      AppTheme.colorRecoveryAmber,
      0.08,
    )!;
    final days = goal.daysRemaining ?? 0;
    final overdueDays = days.abs();
    final pct = (goal.progressPercent * 100).round();

    return _CardShell(
      goal: goal,
      backgroundColor: bg,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GoalIcon(
                iconPath: goal.iconPath,
                color: AppTheme.colorRecoveryAmber,
              ),
              const Spacer(),
              // Recovery Mode badge (never 'Overdue')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colorRecoveryAmber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.colorRecoveryAmber,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Recovery Mode',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.colorRecoveryAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            goal.title,
            style: AppTheme.titleLarge.copyWith(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '$overdueDays day${overdueDays == 1 ? '' : 's'} overdue',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.colorRecoveryAmber,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 6.0,
            percent: goal.progressPercent,
            progressColor: AppTheme.colorRecoveryAmber,
            backgroundColor: AppTheme.colorSurfaceAlt,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 800,
          ),
          const SizedBox(height: 8),
          // Coach nudge (short — PRD §6.3 State 2)
          Text(
            'You are $pct% there. Keep going!',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.colorRecoveryAmber,
            ),
          ),
        ],
      ),
    );
  }
}

// ── State 3: Completed card ───────────────────────────────
class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.goal, this.onTap, this.onLongPress});
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final accentColor = hexToColor(goal.accentColorHex);

    return _CardShell(
      goal: goal,
      backgroundColor: AppTheme.colorSurface,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          // 30% neon green wash overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.colorNeonGreen.withOpacity(0.30),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _GoalIcon(iconPath: goal.iconPath, color: accentColor),
                  const Spacer(),
                  // Completed badge with checkmark
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.colorNeonGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.colorNeonGreen,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.colorNeonGreen,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.colorNeonGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                goal.title,
                style: AppTheme.titleLarge.copyWith(fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                formatInr(goal.targetAmount),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.colorNeonGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              LinearPercentIndicator(
                lineHeight: 6.0,
                percent: 1.0,
                progressColor: accentColor,
                backgroundColor: AppTheme.colorSurfaceAlt,
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
              // No countdown, no suggestion on completed cards (PRD §6.3)
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────
class _GoalIcon extends StatelessWidget {
  const _GoalIcon({required this.iconPath, required this.color});
  final String iconPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(6),
      child: SvgPicture.asset(
        iconPath,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (_) => Icon(
          Icons.star_outline,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}

class _MonthlySuggestionChip extends StatelessWidget {
  const _MonthlySuggestionChip({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.colorRecoveryAmber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Save ${formatInr(amount)}/mo',
        style: AppTheme.labelSmall.copyWith(
          color: AppTheme.colorRecoveryAmber,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
