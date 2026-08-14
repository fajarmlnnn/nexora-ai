import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../state/report_state.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(reportSnapshotProvider);
    final analytics = snapshot.current;
    final transactions = snapshot.transactions;
    final categoryEntries = analytics.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = categoryEntries.take(5).toList(growable: false);
    final maxCategory = topCategories.isEmpty ? 0.0 : topCategories.first.value;

    return PremiumScaffold(
      child: ListView(
        padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 24),
        children: [
          Row(
            children: [
              Expanded(child: Text('Report', style: AppTypography.heading1)),
              const _MonthSelector(),
            ],
          ),
          AppSpacing.gapLG,
          Row(children: [
            Expanded(child: MetricPill(icon: LucideIcons.arrowDownLeft, label: 'Income', value: rupiah(analytics.income), color: AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: MetricPill(icon: LucideIcons.arrowUpRight, label: 'Expense', value: rupiah(analytics.expense), color: AppColors.danger)),
          ]),
          AppSpacing.gapLG,
          Row(children: [
            Expanded(child: MetricPill(icon: LucideIcons.percent, label: 'Savings Rate', value: '${(analytics.savingsRate * 100).toStringAsFixed(1)}%', color: AppColors.primaryLight)),
            const SizedBox(width: 12),
            Expanded(child: MetricPill(icon: LucideIcons.badgeCheck, label: 'Net Cashflow', value: '${analytics.netCashflow >= 0 ? '+' : '-'}${rupiah(analytics.netCashflow.abs())}', color: analytics.netCashflow >= 0 ? AppColors.success : AppColors.danger)),
          ]),
          AppSpacing.gapLG,
          PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader('Perbandingan Bulan'),
            AppSpacing.gapMD,
            _ComparisonRow(label: 'Income', current: analytics.income, change: snapshot.incomeChangePercent, color: AppColors.success),
            _ComparisonRow(label: 'Expense', current: analytics.expense, change: snapshot.expenseChangePercent, color: AppColors.danger, invertChangeColor: true),
          ])),
          AppSpacing.gapLG,
          PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader('Pengeluaran per Kategori'),
            AppSpacing.gapMD,
            if (topCategories.isEmpty)
              Text('Belum ada pengeluaran pada periode ini.', style: AppTypography.bodySmall)
            else
              ...topCategories.map((entry) => _CategoryRow(category: entry.key, amount: entry.value, total: analytics.expense)),
          ])),
          AppSpacing.gapLG,
          PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader('Top Spending'),
            AppSpacing.gapMD,
            if (topCategories.isEmpty)
              Text('Belum cukup data.', style: AppTypography.bodySmall)
            else
              ...topCategories.take(3).map((entry) => _SpendingRow(label: _categoryLabel(entry.key), value: rupiah(entry.value), progress: maxCategory <= 0 ? 0 : entry.value / maxCategory, color: _categoryColor(entry.key))),
          ])),
          AppSpacing.gapLG,
          PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader('Cashflow Mingguan'),
            AppSpacing.gapMD,
            _WeeklyCashflowChart(transactions: transactions, start: analytics.start, end: analytics.end),
          ])),
          AppSpacing.gapLG,
          PremiumCard(child: Row(children: [
            const NexoraRobot(size: 76, waving: false),
            AppSpacing.hGapMD,
            Expanded(child: Text(analytics.transactionCount == 0 ? 'Belum ada transaksi pada periode ini. Mulai mencatat transaksi agar laporan keuangan semakin akurat.' : _reportInsight(analytics), style: AppTypography.bodySmall)),
          ])),
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
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 9),
      Expanded(child: Text(label, style: AppTypography.caption)),
      Text(rupiah(current), style: AppTypography.labelMedium),
      const SizedBox(width: 10),
      Text('${positive ? '+' : ''}${change.toStringAsFixed(1)}%', style: AppTypography.caption.copyWith(color: changeColor)),
    ]));
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
    return Padding(padding: const EdgeInsets.only(bottom: 11), child: Column(children: [
      Row(children: [
        Expanded(child: Text(_categoryLabel(category), style: AppTypography.caption)),
        Text(rupiah(amount), style: AppTypography.caption),
        const SizedBox(width: 8),
        Text('${(percent * 100).toStringAsFixed(1)}%', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 5),
      AnimatedProgressBar(value: percent, color: _categoryColor(category)),
    ]));
  }
}

class _SpendingRow extends StatelessWidget {
  const _SpendingRow({required this.label, required this.value, required this.progress, required this.color});
  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(children: [
    PremiumIconBadge(icon: LucideIcons.circleDollarSign, color: color, size: 38),
    AppSpacing.hGapMD,
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label, style: AppTypography.labelMedium)), Text(value, style: AppTypography.caption.copyWith(color: AppColors.textSecondary))]),
      AppSpacing.gapXS,
      AnimatedProgressBar(value: progress, color: color),
    ])),
  ]));
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
    return SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: weeks.map((week) {
      final incomeHeight = maxValue <= 0 ? 0.0 : (week.$1 / maxValue) * 105;
      final expenseHeight = maxValue <= 0 ? 0.0 : (week.$2 / maxValue) * 105;
      return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
          _Bar(height: incomeHeight, color: AppColors.success),
          const SizedBox(width: 3),
          _Bar(height: expenseHeight, color: AppColors.danger),
        ])),
        const SizedBox(height: 7),
        Text(week.$3, style: AppTypography.caption),
      ]));
    }).toList()));
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});
  final double height;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 10, height: height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)));
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    return InkWell(
      borderRadius: AppRadius.radiusLG,
      onTap: () => _showMonthPicker(context, ref, period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.radiusLG, border: Border.all(color: AppColors.border.withValues(alpha: .55))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_monthLabel(period.start), style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronDown, color: AppColors.textMuted, size: 16),
        ]),
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context, WidgetRef ref, ReportPeriod selected) async {
    final now = DateTime.now();
    final months = List.generate(12, (index) => DateTime(now.year, now.month - index));
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: months.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final month = months[index];
          final isSelected = month.year == selected.start.year && month.month == selected.start.month;
          return ListTile(title: Text(_monthLabel(month)), trailing: isSelected ? const Icon(LucideIcons.check) : null, onTap: () => Navigator.of(context).pop(month));
        },
      )),
    );
    if (picked == null) return;
    ref.read(reportPeriodProvider.notifier).state = ReportPeriod(DateTime(picked.year, picked.month), DateTime(picked.year, picked.month + 1));
  }
}

String _monthLabel(DateTime date) {
  const months = <String>['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
  return '${months[date.month - 1]} ${date.year}';
}

String _categoryLabel(TransactionCategory category) {
  switch (category) {
    case TransactionCategory.food: return 'Makan & Minuman';
    case TransactionCategory.transport: return 'Transportasi';
    case TransactionCategory.shopping: return 'Belanja';
    case TransactionCategory.salary: return 'Gaji';
    case TransactionCategory.investment: return 'Investasi';
    case TransactionCategory.bills: return 'Tagihan';
    case TransactionCategory.entertainment: return 'Hiburan';
    case TransactionCategory.health: return 'Kesehatan';
    case TransactionCategory.education: return 'Pendidikan';
    case TransactionCategory.other: return 'Lainnya';
  }
}

Color _categoryColor(TransactionCategory category) {
  switch (category) {
    case TransactionCategory.food: return AppColors.chartPurple;
    case TransactionCategory.transport: return AppColors.chartBlue;
    case TransactionCategory.shopping: return AppColors.chartOrange;
    case TransactionCategory.salary: return AppColors.success;
    case TransactionCategory.investment: return AppColors.primaryLight;
    case TransactionCategory.bills: return AppColors.danger;
    case TransactionCategory.entertainment: return AppColors.chartGreen;
    case TransactionCategory.health: return AppColors.warning;
    case TransactionCategory.education: return AppColors.info;
    case TransactionCategory.other: return AppColors.textMuted;
  }
}

String _reportInsight(FinancialAnalyticsSnapshot analytics) {
  final top = analytics.topExpenseCategory;
  if (top == null || analytics.expense <= 0) return 'Cashflow periode ini masih positif. Pertahankan pencatatan transaksi agar insight semakin akurat.';
  final percent = top.value / analytics.expense * 100;
  return 'Pengeluaran terbesar periode ini adalah ${_categoryLabel(top.key)} sebesar ${rupiah(top.value)} (${percent.toStringAsFixed(1)}% dari total pengeluaran).';
}
