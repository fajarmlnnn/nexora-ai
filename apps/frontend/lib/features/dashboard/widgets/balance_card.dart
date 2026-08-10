import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../models/dashboard_summary.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.summary,
    this.totalBalance,
    this.onTap,
  });

  final DashboardSummary summary;
  final double? totalBalance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final balance = totalBalance ?? summary.totalBalance;
    final hasComparison = summary.hasBalanceComparison;
    final changePercent = summary.balanceChangePercent;
    final changeColor = hasComparison
        ? (changePercent >= 0 ? AppColors.success : AppColors.danger)
        : AppColors.primaryLight;
    final changeText = hasComparison
        ? '${changePercent >= 0 ? '+' : '-'}${changePercent.abs().toStringAsFixed(1)}%'
        : 'Baru';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusXXL,
        child: NCard(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF171525), Color(0xFF12121C), Color(0xFF0D0E15)],
          ),
          showBorder: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _BalanceHeader(),
                  const Spacer(),
                  _RealtimePill(
                    text: changeText,
                    color: changeColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Total Balance',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  rupiah(balance),
                  style: AppTypography.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _BalanceTrendChart(
                points: summary.balanceTrendPoints,
                accent: AppColors.primaryLight,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FinanceBubble(
                      title: 'Income',
                      value: rupiah(summary.monthlyIncome),
                      status: summary.monthlyIncome > 0 ? 'Tercatat' : 'Belum ada data',
                      icon: Icons.arrow_downward_rounded,
                      accent: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FinanceBubble(
                      title: 'Expense',
                      value: rupiah(summary.monthlyExpense),
                      status: summary.monthlyExpense > 0 ? 'Tercatat' : 'Belum ada data',
                      icon: Icons.arrow_upward_rounded,
                      accent: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Lihat detail',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.primaryLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .45),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Financial Overview',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

class _RealtimePill extends StatelessWidget {
  const _RealtimePill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .16)),
        ),
        child: Text(
          text,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _BalanceTrendChart extends StatelessWidget {
  const _BalanceTrendChart({required this.points, required this.accent});

  final List<double> points;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasEnoughData = points.length >= 2;
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: Colors.white.withValues(alpha: .05)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _BalanceTrendPainter(
                    points: hasEnoughData ? points : const [0, 0],
                    accent: accent,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasEnoughData
                    ? 'Tren saldo real-time bulan ini'
                    : 'Belum cukup data historis',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceTrendPainter extends CustomPainter {
  _BalanceTrendPainter({required this.points, required this.accent});

  final List<double> points;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    final minValue = points.reduce(math.min);
    final maxValue = points.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final paddingX = 8.0;
    final paddingY = 8.0;
    final drawableWidth = math.max(size.width - paddingX * 2, 1);
    final drawableHeight = math.max(size.height - paddingY * 2, 1);

    double xForIndex(int index) {
      if (points.length == 1) return size.width / 2;
      return paddingX + (drawableWidth * index / (points.length - 1));
    }

    double yForValue(double value) {
      final normalized = ((value - minValue) / range).clamp(0.0, 1.0);
      return paddingY + (drawableHeight - (normalized * drawableHeight));
    }

    final linePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final areaPath = Path();
    final linePath = Path();

    final start = Offset(xForIndex(0), yForValue(points.first));
    linePath.moveTo(start.dx, start.dy);
    areaPath.moveTo(start.dx, size.height - 2);
    areaPath.lineTo(start.dx, start.dy);

    for (var i = 1; i < points.length; i++) {
      final point = Offset(xForIndex(i), yForValue(points[i]));
      final previous = Offset(xForIndex(i - 1), yForValue(points[i - 1]));
      final midX = (previous.dx + point.dx) / 2;

      if (i == 1) {
        linePath.quadraticBezierTo(previous.dx, previous.dy, midX, (previous.dy + point.dy) / 2);
        areaPath.quadraticBezierTo(previous.dx, previous.dy, midX, (previous.dy + point.dy) / 2);
      }

      linePath.quadraticBezierTo(previous.dx, previous.dy, point.dx, point.dy);
      areaPath.quadraticBezierTo(previous.dx, previous.dy, point.dx, point.dy);
    }

    areaPath
      ..lineTo(xForIndex(points.length - 1), size.height - 2)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: .32), accent.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(linePath, glowPaint);
    canvas.drawPath(linePath, linePaint);

    final last = Offset(xForIndex(points.length - 1), yForValue(points.last));
    final dotPaint = Paint()..color = accent;
    final dotGlowPaint = Paint()
      ..color = accent.withValues(alpha: .28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(last, 7.5, dotGlowPaint);
    canvas.drawCircle(last, 3.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _BalanceTrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.accent != accent;
  }
}

class _FinanceBubble extends StatelessWidget {
  const _FinanceBubble({
    required this.title,
    required this.value,
    required this.status,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String status;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .035),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: Colors.white.withValues(alpha: .055),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    status,
                    style: AppTypography.caption.copyWith(
                      color: accent.withValues(alpha: .78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
