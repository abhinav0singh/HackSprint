// lib/widgets/spending_analytics_section.dart
// NEW FILE — Add this widget at the BOTTOM of your existing AnalyticsScreen
// scrollable content. Do not replace your existing screen.

import 'package:flutter/material.dart';
import '../core/behavioral_engine.dart';
import '../core/spending_simulator.dart';

class SpendingAnalyticsSection extends StatelessWidget {
  final BehaviorReport report;

  const SpendingAnalyticsSection({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        _sectionDivider(),
        const SizedBox(height: 20),

        // ── Section A: Spending Breakdown ─────────────────────────────────
        _sectionTitle('💸 Monthly Spending Breakdown'),
        const SizedBox(height: 4),
        Text(
          'Income: ₹${_fmt(report.income)}  |  Total Spent: ₹${_fmt(report.totalSpent)}',
          style: const TextStyle(color: Color(0xFF6B6F7A), fontSize: 12),
        ),
        const SizedBox(height: 14),
        ...report.insights.map((insight) => _categoryBar(insight)),

        const SizedBox(height: 24),

        // ── Section B: Intervention Cards ────────────────────────────────
        if (report.harmfulInsights.isNotEmpty) ...[
          _sectionTitle('🚨 Intervention Alerts'),
          const SizedBox(height: 12),
          ...report.harmfulInsights.map((insight) => _interventionCard(insight)),
          const SizedBox(height: 24),
        ],

        // ── Section C: Future Impact Chart ────────────────────────────────
        _sectionTitle('📈 6-Month Savings Projection'),
        const SizedBox(height: 6),
        const Text(
          'Red = current path  •  Green = corrected path',
          style: TextStyle(color: Color(0xFF6B6F7A), fontSize: 11),
        ),
        const SizedBox(height: 12),
        _FutureImpactChart(report: report),
        const SizedBox(height: 8),
        _gapLabel(report),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionDivider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        color: const Color(0xFF2A2D36),
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      );

  Widget _categoryBar(BehaviorInsight insight) {
    final maxValue = insight.spent > insight.threshold ? insight.spent : insight.threshold;
    final spentFraction = (insight.spent / maxValue).clamp(0.0, 1.0);
    final thresholdFraction = insight.threshold / maxValue;
    final barColor = insight.isHarmful ? const Color(0xFFFF9800) : const Color(0xFF00E676);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(insight.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  insight.category,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                if (insight.isHarmful)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('⚠️', style: TextStyle(fontSize: 11)),
                  ),
              ]),
              Text(
                '₹${_fmt(insight.spent)}  (${insight.percentOfIncome.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: barColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              children: [
                // background track
                Container(
                  height: 8,
                  width: width,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D36),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // safe threshold marker line
                Positioned(
                  left: width * thresholdFraction - 1,
                  top: 0,
                  child: Container(
                    width: 2,
                    height: 8,
                    color: Colors.white24,
                  ),
                ),
                // actual spend bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 8,
                  width: width * spentFraction,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 3),
          Text(
            'Safe limit: ₹${_fmt(insight.threshold)} (${(_thresholdPct(insight.category) * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(color: Color(0xFF6B6F7A), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _interventionCard(BehaviorInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFFFF9800), width: 3),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(insight.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  insight.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ]),
              Text(
                '₹${_fmt(insight.spent)}  (${insight.percentOfIncome.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Safe limit: ₹${_fmt(insight.threshold)} (${(_thresholdPct(insight.category) * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(color: Color(0xFF6B6F7A), fontSize: 11),
          ),
          const SizedBox(height: 10),
          Text(
            insight.interventionBody,
            style: const TextStyle(color: Color(0xFFB0B3BA), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF12151C),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Text('📉', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    insight.futureImpact,
                    style: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gapLabel(BehaviorReport report) {
    final gap = report.projectedGapAtMonth6;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'By correcting spending, you could save ₹${_fmt(gap)} more over 6 months.',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _thresholdPct(String category) =>
      SpendingSimulator.kSafeThresholds[category] ?? 0.0;

  static String _fmt(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{2})+\d$)'), (m) => '${m[1]},');
}

// ─── Future Impact Chart (CustomPaint) ────────────────────────────────────────

class _FutureImpactChart extends StatelessWidget {
  final BehaviorReport report;
  const _FutureImpactChart({required this.report});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _ImpactChartPainter(
          projected: report.projectedSavings,
          corrected: report.correctedSavings,
        ),
        child: Container(),
      ),
    );
  }
}

class _ImpactChartPainter extends CustomPainter {
  final List<double> projected;
  final List<double> corrected;

  _ImpactChartPainter({required this.projected, required this.corrected});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = [
      ...projected,
      ...corrected,
    ].reduce((a, b) => a > b ? a : b);

    const leftPad = 56.0;
    const bottomPad = 28.0;
    const topPad = 12.0;
    final chartWidth = size.width - leftPad;
    final chartHeight = size.height - bottomPad - topPad;
    final months = projected.length;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF2A2D36)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartHeight * (1 - i / 4);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width, y),
        gridPaint,
      );
      // Y axis labels
      final label = '₹${_shortFmt(maxVal * i / 4)}';
      _drawText(canvas, label, Offset(0, y - 6), 9, const Color(0xFF6B6F7A));
    }

    // X axis labels
    for (int i = 0; i < months; i++) {
      final x = leftPad + chartWidth * i / (months - 1);
      _drawText(
        canvas,
        'M${i + 1}',
        Offset(x - 8, size.height - bottomPad + 6),
        9,
        const Color(0xFF6B6F7A),
      );
    }

    // Draw lines
    _drawLine(canvas, projected, maxVal, leftPad, topPad, chartWidth, chartHeight,
        const Color(0xFFE53935), months);
    _drawLine(canvas, corrected, maxVal, leftPad, topPad, chartWidth, chartHeight,
        const Color(0xFF00E676), months);

    // Dots on last point
    final lastX = leftPad + chartWidth;
    _drawDot(canvas, lastX,
        topPad + chartHeight * (1 - projected.last / maxVal),
        const Color(0xFFE53935));
    _drawDot(canvas, lastX,
        topPad + chartHeight * (1 - corrected.last / maxVal),
        const Color(0xFF00E676));

    // Labels at M6
    _drawText(
      canvas,
      '₹${_shortFmt(projected.last)}',
      Offset(lastX - 40, topPad + chartHeight * (1 - projected.last / maxVal) + 4),
      9,
      const Color(0xFFE53935),
    );
    _drawText(
      canvas,
      '₹${_shortFmt(corrected.last)}',
      Offset(lastX - 40, topPad + chartHeight * (1 - corrected.last / maxVal) - 14),
      9,
      const Color(0xFF00E676),
    );
  }

  void _drawLine(Canvas canvas, List<double> data, double maxVal,
      double leftPad, double topPad, double chartWidth, double chartHeight,
      Color color, int months) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = leftPad + chartWidth * i / (months - 1);
      final y = topPad + chartHeight * (1 - data[i] / maxVal);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawDot(Canvas canvas, double x, double y, Color color) {
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
    canvas.drawCircle(
        Offset(x, y), 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  String _shortFmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}