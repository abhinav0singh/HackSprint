import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/aggregate_provider.dart';
import '../providers/goal_provider.dart';

// ─────────────────────────────────────────────────────────
// TotalProgressRing  (PRD §5.2.1 — Exact Spec)
//
// Widget: CircularPercentIndicator
// Radius: 100.0  |  lineWidth: 14.0
// progressColor: #00E676
// backgroundColor: #2A2D36
// animation: true  |  animationDuration: 1200ms
// curve: Curves.easeInOut
// Center: percentage (48sp bold white) + INR compact labels
// Glow: BoxShadow color #00E676 @ 40% opacity, blur 28, spread 4
// Below ring: 'across N goals' | if overdue: 'N overdue' in amber
// ─────────────────────────────────────────────────────────

class TotalProgressRing extends ConsumerWidget {
  const TotalProgressRing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregate  = ref.watch(aggregateProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final hasGoals   = (goalsAsync.value?.isNotEmpty) ?? false;

    // Empty state: grey ring, no glow
    if (!hasGoals) return const _EmptyRing();

    final percent      = aggregate.totalPercent;
    final allCompleted = aggregate.totalTarget > 0 &&
        aggregate.totalSaved >= aggregate.totalTarget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: hasGoals
                ? AppTheme.neonGlow(
                    blurRadius: 28,
                    spreadRadius: 4,
                  )
                : null,
          ),
          child: CircularPercentIndicator(
            radius: 100.0,
            lineWidth: 14.0,
            percent: percent,
            animation: true,
            animationDuration: 1200,
            animateFromLastPercent: true,
            curve: Curves.easeInOut,
            progressColor: AppTheme.colorNeonGreen,
            backgroundColor: AppTheme.colorSurface,
            circularStrokeCap: CircularStrokeCap.round,
            center: _RingCenter(
              percent: percent,
              totalSaved: aggregate.totalSaved,
              totalTarget: aggregate.totalTarget,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _BelowRingLabel(
          goalCount: aggregate.goalCount,
          overdueCount: aggregate.overdueCount,
          allCompleted: allCompleted,
        ),
      ],
    );
  }
}

// ── Ring Center content ───────────────────────────────────
class _RingCenter extends StatelessWidget {
  const _RingCenter({
    required this.percent,
    required this.totalSaved,
    required this.totalTarget,
  });

  final double percent;
  final double totalSaved;
  final double totalTarget;

  @override
  Widget build(BuildContext context) {
    final pctInt = (percent * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$pctInt%',
          style: AppTheme.displayLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '${inrCompact(totalSaved)} saved',
          style: AppTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
        Text(
          'of ${inrCompact(totalTarget)}',
          style: AppTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Below ring label ─────────────────────────────────────
class _BelowRingLabel extends StatelessWidget {
  const _BelowRingLabel({
    required this.goalCount,
    required this.overdueCount,
    required this.allCompleted,
  });

  final int goalCount;
  final int overdueCount;
  final bool allCompleted;

  @override
  Widget build(BuildContext context) {
    if (allCompleted && goalCount > 0) {
      return Text(
        '🎉 All goals reached!',
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.colorNeonGreen,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'across $goalCount goal${goalCount == 1 ? '' : 's'}',
          style: AppTheme.labelSmall,
        ),
        if (overdueCount > 0) ...[
          const SizedBox(height: 4),
          Text(
            '$overdueCount overdue',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.colorRecoveryAmber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Empty State Ring (PRD §5.2.2) ────────────────────────
class _EmptyRing extends StatelessWidget {
  const _EmptyRing();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: 100.0,
          lineWidth: 14.0,
          percent: 0.0,
          progressColor: AppTheme.colorDivider,
          backgroundColor: AppTheme.colorSurface,
          circularStrokeCap: CircularStrokeCap.round,
          center: const Icon(
            Icons.savings_outlined,
            color: AppTheme.colorTextSecondary,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Add your first goal to get started!',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


