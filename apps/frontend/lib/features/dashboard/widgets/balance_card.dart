import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_summary.dart';
import '../models/transaction_model.dart';

class BalanceCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = totalBalance ?? summary.totalBalance;
    final transactions = ref.watch(financialTransactionsProvider);

    final trend = _buildBalanceTrend(transactions, balance);
    final now = DateUtils.dateOnly(DateTime.now());
    final monthlyIncomeChange = _compareMonthlyPercent(
      transactions,
      now.year,
      now.month,
      (item) => item.isIncome,
    );
    final monthlyExpenseChange = _compareMonthlyPercent(
      transactions,
      now.year,
      now.month,
      (item) => item.isExpense,
    );

    final changeText = trend.hasComparison
        ? '${trend.changePercent >= 0 ? '+' : '-'}${trend.changePercent.abs().toStringAsFixed(1)}%'
        : 'Baru';
    final changeSubtext = trend.hasComparison ? 'vs awal bulan' : 'Data baru';
    final changeColor = trend.hasComparison
        ? (trend.changePercent >= 0 ? AppColors.success : AppColors.danger)
        : AppColors.primaryLight;

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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _BalanceHeader(),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        changeText,
                        style: AppTypography.caption.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        changeSubtext,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _BalanceTrendChart(
                points: trend.points,
                accent: AppColors.primaryLight,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FinanceBubble(
                      title: 'Income',
                      value: rupiah(summary.monthlyIncome),
                      trendText: _formatPercent(monthlyIncomeChange),
                      trendColor: monthlyIncomeChange >= 0
                          ? AppColors.success
                          : AppColors.danger,
                      icon: Icons.arrow_downward_rounded,
                      accent: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FinanceBubble(
                      title: 'Expense',
                      value: rupiah(summary.monthlyExpense),
                      trendText: _formatPercent(monthlyExpenseChange),
                      trendColor: monthlyExpenseChange >= 0
                          ? AppColors.danger
                          : AppColors.success,
                      icon: Icons.arrow_upward_rounded,
                      accent: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
                  color: AppColors.primary.withValues(alpha: .35),
                  blurRadius: 8,
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

class _BalanceTrendChart extends StatelessWidget {
  const _BalanceTrendChart({required this.points, required this.accent});

  final List<double> points;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasEnoughData = points.length >= 2;
    return SizedBox(
      height: 88,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .02),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: Colors.white.withValues(alpha: .04)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
          child: CustomPaint(
            painter: _BalanceTrendPainter(
              points: hasEnoughData ? points : const [0, 0],
              accent: accent,
            ),
            child: const SizedBox.expand(),
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

    const paddingX = 6.0;
    const paddingY = 6.0;
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

    final offsets = List<Offset>.generate(
      points.length,
      (index) => Offset(xForIndex(index), yForValue(points[index])),
    );

    final linePath = _buildSmoothPath(offsets);
    final areaPath = Path()
      ..addPath(linePath, Offset.zero)
      ..lineTo(offsets.last.dx, size.height - 1)
      ..lineTo(offsets.first.dx, size.height - 1)
      ..close();

    final linePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: .14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: .16), accent.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(linePath, glowPaint);
    canvas.drawPath(linePath, linePaint);

    final last = offsets.last;
    final dotPaint = Paint()..color = accent;
    final dotGlowPaint = Paint()
      ..color = accent.withValues(alpha: .22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(last, 5.6, dotGlowPaint);
    canvas.drawCircle(last, 3.0, dotPaint);
  }

  Path _buildSmoothPath(List<Offset> points) {
    if (points.length < 2) {
      return Path()..moveTo(points.first.dx, points.first.dy);
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    return path;
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
    required this.trendText,
    required this.trendColor,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String trendText;
  final Color trendColor;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: Colors.white.withValues(alpha: .05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: accent),
            ),
            const SizedBox(width: 8),
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
                  const SizedBox(height: 2),
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
                  const SizedBox(height: 2),
                  Text(
                    trendText,
                    style: AppTypography.caption.copyWith(
                      color: trendColor,
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

_BalanceTrend _buildBalanceTrend(List<TransactionModel> transactions, double currentBalance) {
  final now = DateUtils.dateOnly(DateTime.now());
  final currentMonthTransactions = transactions
      .where(
        (item) =>
            item.date.year == now.year &&
            item.date.month == now.month &&
            !item.isTransfer,
      )
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final currentMonthIncome = currentMonthTransactions.fold<double>(
    0.0,
    (sum, item) => sum + (item.isIncome ? item.amount : 0.0),
  );
  final currentMonthExpense = currentMonthTransactions.fold<double>(
    0.0,
    (sum, item) => sum + (item.isExpense ? item.amount : 0.0),
  );

  final monthStartBalance = currentBalance - currentMonthIncome + currentMonthExpense;
  final monthBase = monthStartBalance <= 0 ? currentBalance : monthStartBalance;
  final changePercent = monthBase <= 0
      ? 0.0
      : ((currentBalance - monthBase) / monthBase) * 100;

  final dailyDeltas = <int, double>{};
  for (final transaction in currentMonthTransactions) {
    final delta = transaction.isIncome
        ? transaction.amount
        : transaction.isExpense
            ? -transaction.amount
            : 0.0;
    dailyDeltas[transaction.date.day] =
        (dailyDeltas[transaction.date.day] ?? 0.0) + delta;
  }

  final points = <double>[];
  var balance = monthBase;
  final dayCount = now.day < 2 ? 2 : now.day;
  for (var day = 1; day <= dayCount; day++) {
    balance += dailyDeltas[day] ?? 0.0;
    points.add(balance);
  }

  if (points.length == 1) {
    points.add(currentBalance);
  }

  return _BalanceTrend(
    previousBalance: monthBase,
    changePercent: changePercent,
    points: List<double>.unmodifiable(points),
  );
}

double _compareMonthlyPercent(
  List<TransactionModel> transactions,
  int year,
  int month,
  bool Function(TransactionModel transaction) predicate,
) {
  final current = _sumForMonth(transactions, year, month, predicate);
  final previousDate = DateTime(year, month - 1);
  final previous = _sumForMonth(
    transactions,
    previousDate.year,
    previousDate.month,
    predicate,
  );

  if (previous <= 0) return 0.0;
  return ((current - previous) / previous) * 100;
}

double _sumForMonth(
  List<TransactionModel> transactions,
  int year,
  int month,
  bool Function(TransactionModel transaction) predicate,
) {
  return transactions.fold<double>(
    0.0,
    (sum, item) =>
        item.date.year == year &&
        item.date.month == month &&
        !item.isTransfer &&
        predicate(item)
            ? sum + item.amount
            : sum,
  );
}

String _formatPercent(double value) {
  if (value.abs() < 0.05) return '0.0%';
  final sign = value > 0 ? '+' : '-';
  return '$sign${value.abs().toStringAsFixed(1)}%';
}

class _BalanceTrend {
  const _BalanceTrend({
    required this.previousBalance,
    required this.changePercent,
    required this.points,
  });

  final double previousBalance;
  final double changePercent;
  final List<double> points;

  bool get hasComparison => previousBalance > 0;
}
