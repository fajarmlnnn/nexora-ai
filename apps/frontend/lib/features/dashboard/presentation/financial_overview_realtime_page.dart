import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/context_ai_insight.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/financial_overview_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';

class FinancialOverviewRealtimePage extends ConsumerWidget {
  const FinancialOverviewRealtimePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(totalWalletBalanceProvider);
    final goalSaved = ref.watch(totalGoalSavedProvider);
    final goalTarget = ref.watch(totalGoalTargetProvider);
    final debt = ref.watch(totalInstallmentRemainingProvider);
    final due = ref.watch(installmentDueThisPeriodProvider);
    final installments = ref.watch(installmentsProvider);
    final transactions = ref.watch(recentTransactionsProvider).valueOrNull ?? const [];

    final income = transactions.where((item) => item.isIncome).fold<double>(0, (sum, item) => sum + item.amount);
    final expense = transactions.where((item) => item.isExpense).fold<double>(0, (sum, item) => sum + item.amount);
    final cashflow = income - expense;
    final netWorth = assets - debt;
    final goalProgress = goalTarget <= 0 ? 0.0 : (goalSaved / goalTarget).clamp(0.0, 1.0);
    final available = assets - goalSaved - due;

    return PremiumScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(LucideIcons.arrowLeft, size: 20)),
            const SizedBox(width: 4),
            Expanded(child: Text('Financial Overview', style: AppTypography.heading2)),
          ]),
          const SizedBox(height: 10),
          NCard(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF171525), Color(0xFF12121C), Color(0xFF0D0E15)]),
            showBorder: true,
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Net Worth', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(rupiah(netWorth), style: AppTypography.heading1.copyWith(color: Colors.white, fontWeight: FontWeight.w800))),
              const SizedBox(height: 6),
              Text('Total aset dikurangi seluruh kewajiban tercatat.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Metric(label: 'Total Aset', value: rupiah(assets), icon: LucideIcons.wallet, accent: AppColors.primaryLight)),
            const SizedBox(width: 8),
            Expanded(child: _Metric(label: 'Kewajiban', value: rupiah(debt), icon: LucideIcons.creditCard, accent: AppColors.danger)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _Metric(label: 'Goal', value: rupiah(goalSaved), icon: LucideIcons.target, accent: AppColors.primaryLight)),
            const SizedBox(width: 8),
            Expanded(child: _Metric(label: 'Jatuh Tempo', value: rupiah(due), icon: LucideIcons.calendarClock, accent: AppColors.warning)),
          ]),
          const SizedBox(height: 12),
          _Section(title: 'Goals', trailing: '${(goalProgress * 100).round()}%', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: goalProgress, minHeight: 7, backgroundColor: AppColors.border.withValues(alpha: .35), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight))),
            const SizedBox(height: 7),
            Text('${rupiah(goalSaved)} dari ${rupiah(goalTarget)} target', style: AppTypography.bodySmall),
          ])),
          const SizedBox(height: 8),
          _Section(title: 'Cicilan & Kewajiban', trailing: rupiah(debt), child: Column(children: [
            for (final item in installments)
              Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [
                Expanded(child: Text(item.title, style: AppTypography.bodySmall)),
                Text(rupiah(item.monthlyAmount), style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text(item.isPaid ? 'Lunas' : '${item.dueInDays} hari', style: AppTypography.caption.copyWith(color: item.isPaid ? AppColors.success : AppColors.warning)),
              ])),
            Align(alignment: Alignment.centerLeft, child: Text('Jatuh tempo periode ini: ${rupiah(due)}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary))),
          ])),
          const SizedBox(height: 8),
          _Section(title: 'Available', trailing: rupiah(available), child: Text(available < 0 ? 'Defisit setelah alokasi goal dan kewajiban periode ini.' : 'Estimasi dana setelah alokasi goal dan kewajiban periode ini.', style: AppTypography.bodySmall)),
          const SizedBox(height: 8),
          _Section(title: 'Cashflow', trailing: _signed(cashflow), child: Text('Income ${rupiah(income)} • Expense ${rupiah(expense)}', style: AppTypography.bodySmall)),
          const SizedBox(height: 12),
          ContextAIInsight(title: 'Financial Overview', message: _ai(assets: assets, debt: debt, cashflow: cashflow, available: available)),
        ],
      ),
    );
  }

  static String _signed(double value) => value == 0 ? rupiah(0) : value > 0 ? '+${rupiah(value)}' : '-${rupiah(value.abs())}';

  static String _ai({required double assets, required double debt, required double cashflow, required double available}) {
    if (assets == 0) return 'Belum ada saldo wallet yang terbaca. Tambahkan wallet agar Nexora bisa menganalisis kondisi keuanganmu.';
    if (available < 0) return 'Kewajiban periode ini lebih besar daripada dana yang tersedia setelah alokasi goal. Prioritaskan cicilan sebelum pengeluaran non-esensial.';
    if (cashflow < 0) return 'Cashflow periode ini negatif. Pengeluaran lebih besar daripada pemasukan yang tercatat.';
    if (debt > assets) return 'Total kewajiban lebih besar daripada saldo wallet saat ini. Jaga likuiditas dan hindari menambah cicilan baru dulu.';
    return 'Kondisi keuangan saat ini cukup terkendali. Cashflow positif dan kewajiban masih berada di bawah total aset yang terbaca.';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon, required this.accent});
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => NCard(showBorder: true, padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 30, height: 30, decoration: BoxDecoration(color: accent.withValues(alpha: .10), shape: BoxShape.circle), child: Icon(icon, size: 15, color: accent)),
    const SizedBox(height: 8),
    Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
    const SizedBox(height: 3),
    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800))),
  ]));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.trailing, required this.child});
  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => NCard(showBorder: true, padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700))), Flexible(child: Text(trailing, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)))]),
    const SizedBox(height: 10),
    child,
  ]));
}
