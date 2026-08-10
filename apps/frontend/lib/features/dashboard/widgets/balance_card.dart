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
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    final dailyIncomeChange = _comparePercent(
      _sumForDay(transactions, today, (item) => item.isIncome),
      _sumForDay(transactions, yesterday, (item) => item.isIncome),
    );
    final dailyExpenseChange = _comparePercent(
      _sumForDay(transactions, today, (item) => item.isExpense),
      _sumForDay(transactions, yesterday, (item) => item.isExpense),
    );

    final balancePillColor = trend.changePercent >= 0
        ? AppColors.success
        : AppColors.danger;
    final balancePillText = _formatPercent(trend.changePercent);

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
                  Expanded(
                    child: Text(
                      'Total Balance',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _PercentPill(
                    text: balancePillText,
                    color: balancePillColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 12),
              _BalanceTrendChart(
                points: trend.points,
                accent: AppColors.primaryLight,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _FinanceBubble(
                      title: 'Income',
                      value: rupiah(summary.monthlyIncome),
                      trendText: _formatPercent(dailyIncomeChange),
                      trendColor: dailyIncomeChange >= 0
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
                      trendText: _formatPercent(dailyExpenseChange),
                      trendColor: dailyExpenseChange >= 0
                          ? AppColors.danger
                          : AppColors.success,
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

class _PercentPill extends StatelessWidget {
  const _PercentPill({required this.text, required this.color});

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
      height: 104,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: Colors.white.withValues(alpha: .05)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
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

    const paddingX = 8.0;
    const paddingY = 8.0;
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
      ..color = accent.withValues(alpha: .24)
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
      final midY = (previous.dy + point.dy) / 2;

      linePath.quadraticBezierTo(previous.dx, previous.dy, midX, midY);
      areaPath.quadraticBezierTo(previous.dx, previous.dy, midX, midY);
      linePath.quadraticBezierTo(midX, midY, point.dx, point.dy);
      areaPath.quadraticBezierTo(midX, midY, point.dx, point.dy);
    }

    areaPath
      ..lineTo(xForIndex(points.length - 1), size.height - 2)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: .30), accent.withValues(alpha: 0)],
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
  final todayIncome = _sumForDay(transactions, now, (item) => item.isIncome);
  final todayExpense = _sumForDay(transactions, now, (item) => item.isExpense);
  final previousBalance = currentBalance - todayIncome + todayExpense;
  final changePercent = _comparePercent(currentBalance, previousBalance);

  final points = <double>[monthStartBalance];
  var balance = monthStartBalance;
  for (final transaction in currentMonthTransactions) {
    final delta = transaction.isIncome
        ? transaction.amount
        : transaction.isExpense
            ? -transaction.amount
            : 0.0;
    balance += delta;
    points.add(balance);
  }

  if (points.length == 1) {
    points.add(currentBalance);
  }

  return _BalanceTrend(
    previousBalance: previousBalance,
    changePercent: changePercent,
    points: List<double>.unmodifiable(points),
  );
}

double _sumForDay(
  List<TransactionModel> transactions,
  DateTime day,
  bool Function(TransactionModel transaction) predicate,
) {
  return transactions.fold<double>(
    0.0,
    (sum, item) => _sameDay(item.date, day) && predicate(item) ? sum + item.amount : sum,
  );
}

double _comparePercent(double current, double previous) {
  if (previous <= 0) return 0.0;
  return ((current - previous) / previous) * 100;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
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
}
