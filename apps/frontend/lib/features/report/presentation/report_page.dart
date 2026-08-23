import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../state/report_state.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(reportSnapshotProvider);
    final period = ref.watch(reportPeriodProvider);
    final analytics = snapshot.current;
    final transactions = snapshot.transactions;
    final categoryEntries = analytics.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = categoryEntries.take(5).toList(growable: false);

    return NexoraScaffold(
      appBar: const NexoraAppBar(title: 'Laporan', subtitle: 'Arus kas bulanan'),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          NexoraPeriodPicker(
            month: period.start,
            onChanged: (month) {
              ref.read(reportPeriodProvider.notifier).state = ReportPeriod(
                DateTime(month.year, month.month),
                DateTime(month.year, month.month + 1),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(child: MetricPill(icon: LucideIcons.arrowDownLeft, label: 'Pemasukan', value: rupiah(analytics.income), color: AppColors.success)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: MetricPill(icon: LucideIcons.arrowUpRight, label: 'Pengeluaran', value: rupiah(analytics.expense), color: AppColors.danger)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: MetricPill(icon: LucideIcons.percent, label: 'Rasio tabungan', value: '${(analytics.savingsRate * 100).toStringAsFixed(1)}%', color: AppColors.brandBright)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: MetricPill(icon: LucideIcons.badgeCheck, label: 'Net cashflow', value: '${analytics.netCashflow >= 0 ? '+' : '-'}${rupiah(analytics.netCashflow.abs())}', color: analytics.netCashflow >= 0 ? AppColors.success : AppColors.danger)),
          ]),
          const SizedBox(height: AppSpacing.lg),
          NexoraSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NexoraSectionHeader(title: 'Perbandingan bulan'),
                const SizedBox(height: AppSpacing.md),
                _ComparisonRow(label: 'Pemasukan', current: analytics.income, change: snapshot.incomeChangePercent, color: AppColors.success),
                _ComparisonRow(label: 'Pengeluaran', current: analytics.expense, change: snapshot.expenseChangePercent, color: AppColors.danger, invertChangeColor: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          NexoraSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NexoraSectionHeader(title: 'Pengeluaran per kategori'),
                const SizedBox(height: AppSpacing.md),
                if (topCategories.isEmpty)
                  Text('Belum ada pengeluaran pada periode ini.', style: AppTypography.bodySmall)
                else
                  ...topCategories.map((entry) => _CategoryRow(category: entry.key, amount: entry.value, total: analytics.expense)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          NexoraSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NexoraSectionHeader(title: 'Arus kas mingguan'),
                const SizedBox(height: AppSpacing.md),
                _WeeklyCashflowChart(transactions: transactions, start: analytics.start, end: analytics.end),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          NexoraBanner(
            title: 'Analisis',
            message: analytics.transactionCount == 0
                ? 'Belum ada transaksi pada periode ini. Mulai mencatat transaksi agar laporan semakin akurat.'
                : _reportInsight(analytics),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.current, required this.change, required this.color, this.invertChangeColor = false});
  final String label;
  final double current;
  final double change;
  final Color color;
  final bool invertChangeColor;

  @override
  Widget build(BuildContext context) {
    final positive = change >= 0;
    final changeColor = invertChangeColor ? (positive ? AppColors.danger : AppColors.success) : (positive ? AppColors.success : AppColors.danger);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTypography.caption)),
        Text(rupiah(current), style: AppTypography.labelMedium),
        const SizedBox(width: AppSpacing.sm),
        Text('${positive ? '+' : ''}${change.toStringAsFixed(1)}%', style: AppTypography.caption.copyWith(color: changeColor)),
      ]),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.amount, required this.total});
  final TransactionCategory category;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0.0 : amount / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(category.labelId, style: AppTypography.caption)),
          Text(rupiah(amount), style: AppTypography.caption),
          const SizedBox(width: AppSpacing.xs),
          Text('${(percent * 100).toStringAsFixed(1)}%', style: AppTypography.caption),
        ]),
        const SizedBox(height: AppSpacing.xxs),
        NexoraProgress(value: percent, color: AppColors.brand),
      ]),
    );
  }
}

class _WeeklyCashflowChart extends StatelessWidget {
  const _WeeklyCashflowChart({required this.transactions, required this.start, required this.end});
  final List<TransactionModel> transactions;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final weeks = List.generate(5, (index) {
      final weekStart = start.add(Duration(days: index * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      var income = 0.0;
      var expense = 0.0;
      for (final transaction in transactions) {
        if (transaction.date.isBefore(weekStart) || !transaction.date.isBefore(weekEnd) || transaction.date.isBefore(start) || !transaction.date.isBefore(end)) continue;
        if (transaction.isIncome) income += transaction.amount;
        if (transaction.isExpense) expense += transaction.amount;
      }
      return (income, expense, '${weekStart.day}-${weekEnd.subtract(const Duration(days: 1)).day}');
    });
    final maxValue = weeks.fold<double>(0, (max, item) => [max, item.$1, item.$2].reduce((a, b) => a > b ? a : b));
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weeks.map((week) {
          final incomeHeight = maxValue <= 0 ? 0.0 : (week.$1 / maxValue) * 105;
          final expenseHeight = maxValue <= 0 ? 0.0 : (week.$2 / maxValue) * 105;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Bar(height: incomeHeight, color: AppColors.success),
                      const SizedBox(width: AppSpacing.xxs),
                      _Bar(height: expenseHeight, color: AppColors.danger),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(week.$3, style: AppTypography.caption),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});
  final double height;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 8, height: height, decoration: const BoxDecoration(borderRadius: AppRadius.radiusPill), child: ColoredBox(color: color));
}

String _reportInsight(FinancialAnalyticsSnapshot analytics) {
  final top = analytics.topExpenseCategory;
  if (top == null || analytics.expense <= 0) {
    return 'Arus kas periode ini masih positif. Pertahankan pencatatan transaksi agar analisis semakin akurat.';
  }
  final percent = top.value / analytics.expense * 100;
  return 'Pengeluaran terbesar periode ini adalah ${top.key.labelId} sebesar ${rupiah(top.value)} (${percent.toStringAsFixed(1)}% dari total pengeluaran).';
}
