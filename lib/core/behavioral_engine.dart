// lib/core/behavioral_engine.dart
// NEW FILE — Do not modify existing files

import 'spending_simulator.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class BehaviorInsight {
  final String category;
  final String emoji;
  final double spent;
  final double threshold;      // safe spending limit in INR
  final double percentOfIncome;
  final bool isHarmful;
  final String interventionTitle;
  final String interventionBody;
  final String futureImpact;   // what happens if unchanged for 6 months

  const BehaviorInsight({
    required this.category,
    required this.emoji,
    required this.spent,
    required this.threshold,
    required this.percentOfIncome,
    required this.isHarmful,
    required this.interventionTitle,
    required this.interventionBody,
    required this.futureImpact,
  });

  double get overspend => isHarmful ? (spent - threshold) : 0;
}

class BehaviorReport {
  final List<BehaviorInsight> insights;
  final double totalSpent;        // excluding savings
  final double totalSaved;
  final double income;
  final double savingsRate;       // totalSaved / income
  final bool isAtRisk;            // savingsRate < 0.20
  final String overallMessage;
  final List<double> projectedSavings;   // next 6 months if unchanged
  final List<double> correctedSavings;   // next 6 months if corrected

  const BehaviorReport({
    required this.insights,
    required this.totalSpent,
    required this.totalSaved,
    required this.income,
    required this.savingsRate,
    required this.isAtRisk,
    required this.overallMessage,
    required this.projectedSavings,
    required this.correctedSavings,
  });

  List<BehaviorInsight> get harmfulInsights =>
      insights.where((i) => i.isHarmful).toList();

  double get projectedGapAtMonth6 =>
      correctedSavings.last - projectedSavings.last;
}

// ─── Engine ───────────────────────────────────────────────────────────────────

class BehavioralEngine {
  static BehaviorReport analyze(List<SimulatedTransaction> transactions) {
    const income = kSimulatedMonthlyIncome;
    final summary = SpendingSimulator.summarizeByCategory(transactions);

    // Extract per-category amounts (default 0 if not present)
    final foodSpent          = summary[SpendingSimulator.kFood] ?? 0;
    final entertainmentSpent = summary[SpendingSimulator.kEntertainment] ?? 0;
    final shoppingSpent      = summary[SpendingSimulator.kShopping] ?? 0;
    final transportSpent     = summary[SpendingSimulator.kTransport] ?? 0;
    final savedAmount        = summary[SpendingSimulator.kSavings] ?? 0;

    // Safe thresholds in INR
    final thresholds = SpendingSimulator.kSafeThresholds
        .map((k, v) => MapEntry(k, v * income));

    // Build insights
    final insights = <BehaviorInsight>[
      _buildInsight(
        category: SpendingSimulator.kFood,
        emoji: '🍕',
        spent: foodSpent,
        threshold: thresholds[SpendingSimulator.kFood]!,
        income: income,
        harmfulTitle: 'Food budget exceeded',
        harmfulBody: 'You\'ve spent ₹${_fmt(foodSpent)} on food — ₹${_fmt(foodSpent - thresholds[SpendingSimulator.kFood]!)} over the safe limit.',
        harmfulImpact: 'Over 6 months you\'ll spend ₹${_fmt((foodSpent - thresholds[SpendingSimulator.kFood]!) * 6)} extra on food instead of building savings.',
        safeBody: 'Great job! Your food spending is within the 15% safe limit.',
      ),
      _buildInsight(
        category: SpendingSimulator.kEntertainment,
        emoji: '🎮',
        spent: entertainmentSpent,
        threshold: thresholds[SpendingSimulator.kEntertainment]!,
        income: income,
        harmfulTitle: 'Entertainment is draining your goals',
        harmfulBody: 'You spent ₹${_fmt(entertainmentSpent)} on entertainment — ₹${_fmt(entertainmentSpent - thresholds[SpendingSimulator.kEntertainment]!)} above the safe 10% limit. In-app purchases alone account for a large share.',
        harmfulImpact: 'At this rate, you\'ll spend ₹${_fmt((entertainmentSpent - thresholds[SpendingSimulator.kEntertainment]!) * 6)} extra on entertainment over 6 months — enough to fully fund a savings goal.',
        safeBody: 'Your entertainment spending is within the 10% safe limit.',
      ),
      _buildInsight(
        category: SpendingSimulator.kShopping,
        emoji: '🛍️',
        spent: shoppingSpent,
        threshold: thresholds[SpendingSimulator.kShopping]!,
        income: income,
        harmfulTitle: 'Shopping is your biggest risk',
        harmfulBody: 'You spent ₹${_fmt(shoppingSpent)} on shopping — ₹${_fmt(shoppingSpent - thresholds[SpendingSimulator.kShopping]!)} above the 20% safe limit. Frequent Myntra and Amazon orders are adding up.',
        harmfulImpact: 'If this continues, you\'ll overspend ₹${_fmt((shoppingSpent - thresholds[SpendingSimulator.kShopping]!) * 6)} on shopping over 6 months, delaying your Laptop goal by ~3 months.',
        safeBody: 'Shopping is within the 20% safe limit.',
      ),
      _buildInsight(
        category: SpendingSimulator.kTransport,
        emoji: '🚗',
        spent: transportSpent,
        threshold: thresholds[SpendingSimulator.kTransport]!,
        income: income,
        harmfulTitle: 'Transport budget slightly high',
        harmfulBody: 'Transport spending is ₹${_fmt(transportSpent)}, above the 8% safe limit.',
        harmfulImpact: 'Consider metro/carpooling to save ₹${_fmt((transportSpent - thresholds[SpendingSimulator.kTransport]!) * 6)} over 6 months.',
        safeBody: 'Transport spending is efficient — under the 8% safe limit.',
      ),
    ];

    final totalSpent = foodSpent + entertainmentSpent + shoppingSpent + transportSpent;
    final savingsRate = savedAmount / income;
    final isAtRisk = savingsRate < 0.20;

    // Project savings — next 6 months cumulative
    // Current trajectory: save `savedAmount` per month
    // Corrected trajectory: save what they *should* (20% = ₹10,000) by cutting harmful spend
    final correctedMonthlySavings = income * 0.20;
    final projected = List.generate(6, (i) => savedAmount * (i + 1));
    final corrected = List.generate(6, (i) => correctedMonthlySavings * (i + 1));

    final overallMessage = isAtRisk
        ? 'You saved only ${(savingsRate * 100).toStringAsFixed(0)}% of income this month. '
          'Entertainment + Shopping overspend is the main cause.'
        : 'Good job! Your savings rate of ${(savingsRate * 100).toStringAsFixed(0)}% is on track.';

    return BehaviorReport(
      insights: insights,
      totalSpent: totalSpent,
      totalSaved: savedAmount,
      income: income,
      savingsRate: savingsRate,
      isAtRisk: isAtRisk,
      overallMessage: overallMessage,
      projectedSavings: projected,
      correctedSavings: corrected,
    );
  }

  static BehaviorInsight _buildInsight({
    required String category,
    required String emoji,
    required double spent,
    required double threshold,
    required double income,
    required String harmfulTitle,
    required String harmfulBody,
    required String harmfulImpact,
    required String safeBody,
  }) {
    final pct = spent / income;
    final thresholdPct = SpendingSimulator.kSafeThresholds[category]!;
    final harmful = pct > thresholdPct;

    return BehaviorInsight(
      category: category,
      emoji: emoji,
      spent: spent,
      threshold: threshold,
      percentOfIncome: pct * 100,
      isHarmful: harmful,
      interventionTitle: harmful ? harmfulTitle : '✅ $category on track',
      interventionBody: harmful ? harmfulBody : safeBody,
      futureImpact: harmful ? harmfulImpact : '',
    );
  }

  static String _fmt(double v) =>
      '₹${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+\d$)'), (m) => '${m[1]},')}';
}