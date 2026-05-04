import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';

/// One date+rate pair on the compliance trend chart.
class ComplianceDataPoint {
  const ComplianceDataPoint({required this.date, required this.rate});

  final DateTime date;
  final double rate; // 0.0–1.0
}

/// Line chart showing 30-day compliance with a dashed 80% threshold.
class ComplianceTrendChart extends StatelessWidget {
  const ComplianceTrendChart({
    super.key,
    required this.data,
    this.title,
    this.height = 160,
  });

  final List<ComplianceDataPoint> data;
  final String? title;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Not enough data yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final sorted = [...data]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), (sorted[i].rate * 100).clamp(0, 100)),
    ];
    final lineColor = sorted.last.rate >= AppTheme.complianceThreshold
        ? AppTheme.riskLow
        : AppTheme.riskMedium;

    final dateFmt = DateFormat('d MMM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title!.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              minX: 0,
              maxX: (sorted.length - 1).toDouble().clamp(1, double.infinity),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 25,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}%',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: (sorted.length / 5).clamp(1, 30).toDouble(),
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= sorted.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dateFmt.format(sorted[i].date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: AppTheme.complianceThreshold * 100,
                  color: AppTheme.riskMedium.withValues(alpha: 0.6),
                  strokeWidth: 1.5,
                  dashArray: const [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: TextStyle(
                      color: AppTheme.riskMedium,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    labelResolver: (_) => '80% target',
                  ),
                ),
              ]),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.18,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: sorted.length <= 12,
                    getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                      radius: 3,
                      color: lineColor,
                      strokeColor: Colors.white,
                      strokeWidth: 1.5,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
