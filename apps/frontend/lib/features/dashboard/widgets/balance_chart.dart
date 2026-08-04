import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class BalanceChart extends StatelessWidget {
  const BalanceChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 8,
          minY: 0,
          maxY: 6,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 4,
              color: AppColors.primaryLight,
              shadow: Shadow(
                color: AppColors.primaryLight.withValues(alpha: .85),
                blurRadius: 18,
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: index.isEven ? 2.6 : 0,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: AppColors.primaryLight.withValues(
                        alpha: .45,
                      ),
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryLight.withValues(alpha: .34),
                    AppColors.primaryLight.withValues(alpha: .02),
                  ],
                ),
              ),
              spots: const [
                FlSpot(0, 1.1),
                FlSpot(1, 2.0),
                FlSpot(2, 1.2),
                FlSpot(3, 2.6),
                FlSpot(4, 3.9),
                FlSpot(5, 3.0),
                FlSpot(6, 4.1),
                FlSpot(7, 3.7),
                FlSpot(8, 4.9),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
