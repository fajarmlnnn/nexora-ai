import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BalanceChart extends StatelessWidget {
  const BalanceChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 6,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3,
              color: Colors.white,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.white.withValues(alpha: .12),
              ),
              spots: const [
                FlSpot(0, 1.2),
                FlSpot(1, 2.8),
                FlSpot(2, 2.0),
                FlSpot(3, 3.6),
                FlSpot(4, 3.2),
                FlSpot(5, 4.8),
                FlSpot(6, 4.3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
