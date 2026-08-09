import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/context_ai_insight.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/dashboard_summary.dart';
import '../../wallet/controllers/wallet_controller.dart';

class FinancialOverviewDetailPage extends ConsumerWidget {
  const FinancialOverviewDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final walletsAsync = ref.watch(walletProvider);

    return PremiumScaffold(
      child: summaryAsync.when(
        loading: () => const _Loading(),
        error: (error, _) => Center(
          child: Padding(
            padding: AppSpacing.screen,
            child: EmptyStateCard(
              icon: LucideIcons.triangleAlert,
              title: 'Financial Overview belum tersedia',
              message: error.toString(),
              action: 'Kembali',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        data: (summary) => walletsAsync.when(
          loading: () => const _Loading(),
          error: (error, _) => _OverviewBody(summary: summary, totalAssets: summary.totalBalance),
          data: (wallets) => _OverviewBody(
            summary: summary,
            totalAssets: wallets.where((wallet) => !wallet.isHidden).fold<double>(0, (sum, wallet) => sum + wallet.balance),
          ),
        ),
      ),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.summary, required this.totalAssets});

  final DashboardSummary summary;
  final double totalAssets;

  static const _goalSaved = 26250000.0;
  static const _goalTarget = 132500000.0;
  static const _liabilities = 9250000.0;
  static const _dueThisPeriod = 1700000.0;

  double get netWorth => totalAssets - _liabilities;
  double get netCashflow => summary.monthlyIncome - summary.monthlyExpense;
  double get goalProgress => (_goalSaved / _goalTarget).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 20),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(LucideIcons.arrowLeft, size: 21),
              style: IconButton.styleFrom(backgroundColor: AppColors.card),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('Financial Overview', style: AppTypography.heading1)),
          ],
        ),
        const SizedBox(height: 12),
        PremiumCard(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF171525), Color(0xFF12121C), Color(0xFF0D0E15)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Net Worth', style: AppTypography.caption),
            const SizedBox(height: 5),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(rupiah(netWorth), style: AppTypography.heading1.copyWith(color: Colors.white, fontWeight: FontWeight.w900))),
            const SizedBox(height: 4),
            Text('${rupiah(netCashflow)} net cashflow bulan ini', style: AppTypography.caption.copyWith(color: netCashflow >= 0 ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MetricCard(label: 'Total Aset', value: totalAssets, icon: LucideIcons.walletCards, accent: AppColors.primaryLight)),
          const SizedBox(width: 8),
          Expanded(child: _MetricCard(label: 'Kewajiban', value: _liabilities, icon: LucideIcons.creditCard, accent: AppColors.danger)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _MetricCard(label: 'Goal Terkumpul', value: _goalSaved, icon: LucideIcons.target, accent: AppColors.primaryLight)),
          const SizedBox(width: 8),
          Expanded(child: _MetricCard(label: 'Jatuh Tempo', value: _dueThisPeriod, icon: LucideIcons.calendarClock, accent: AppColors.warning)),
        ]),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Aset Wallet',
          trailing: '${rupiah(totalAssets)}',
          child: const Text('Total aset mengikuti saldo wallet yang terlihat. Perubahan wallet akan tercermin saat state diperbarui.', style: AppTypography.bodySmall),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Goals',
          trailing: '${(goalProgress * 100).round()}%',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${rupiah(_goalSaved)} dari ${rupiah(_goalTarget)}', style: AppTypography.bodySmall),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: AppRadius.radiusPill, child: LinearProgressIndicator(value: goalProgress, minHeight: 7, backgroundColor: AppColors.border.withValues(alpha: .35), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight))),
          ]),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Cicilan & Kewajiban',
          trailing: 'Sisa ${rupiah(_liabilities)}',
          child: const Column(children: [
            _DebtRow(name: 'SPayLater', monthly: 250000, remaining: 1250000),
            SizedBox(height: 8),
            _DebtRow(name: 'Kredit Motor', monthly: 850000, remaining: 6800000),
            SizedBox(height: 8),
            _DebtRow(name: 'Kredit Laptop', monthly: 600000, remaining: 1200000),
          ]),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Cashflow Bulan Ini',
          child: Column(children: [
            _CashflowRow(label: 'Pemasukan', value: summary.monthlyIncome, color: AppColors.success),
            const SizedBox(height: 7),
            _CashflowRow(label: 'Pengeluaran', value: summary.monthlyExpense, color: AppColors.danger),
            const Divider(height: 18, color: Colors.white12),
            _CashflowRow(label: 'Net Cashflow', value: netCashflow, color: netCashflow >= 0 ? AppColors.success : AppColors.danger, strong: true),
          ]),
        ),
        const SizedBox(height: 12),
        ContextAIInsight(
          message: netCashflow >= 0
              ? 'Kondisi cashflow bulan ini masih positif. Setelah kebutuhan dan kewajiban aman, surplus bisa diarahkan ke goal atau dana darurat.'
              : 'Cashflow bulan ini sedang negatif. Prioritaskan kebutuhan dan kewajiban sebelum menambah target baru.',
          actionLabel: 'Lihat saran',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.accent});
  final String label;
  final double value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => PremiumCard(
        padding: const EdgeInsets.all(12),
        borderRadius: AppRadius.radiusXL,
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: AppRadius.radiusLG), child: Icon(icon, size: 17, color: accent)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption), const SizedBox(height: 2), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(rupiah(value), style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))) ])),
        ]),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) => PremiumCard(
        padding: const EdgeInsets.all(13),
        borderRadius: AppRadius.radiusXL,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800))), if (trailing != null) FittedBox(fit: BoxFit.scaleDown, child: Text(trailing!, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 9),
          child,
        ]),
      );
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.name, required this.monthly, required this.remaining});
  final String name;
  final double monthly;
  final double remaining;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .09), borderRadius: AppRadius.radiusLG), child: const Icon(LucideIcons.creditCard, size: 16, color: AppColors.danger)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)), Text('${rupiah(monthly)} / bulan', style: AppTypography.caption)])),
        FittedBox(fit: BoxFit.scaleDown, child: Text(rupiah(remaining), style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800))),
      ]);
}

class _CashflowRow extends StatelessWidget {
  const _CashflowRow({required this.label, required this.value, required this.color, this.strong = false});
  final String label;
  final double value;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(label, style: strong ? AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800) : AppTypography.bodySmall)), FittedBox(fit: BoxFit.scaleDown, child: Text(rupiah(value), style: AppTypography.labelMedium.copyWith(color: color, fontWeight: strong ? FontWeight.w900 : FontWeight.w700)))]);
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => ListView(padding: AppSpacing.screen, children: const [ShimmerSkeleton(width: 190, height: 30), SizedBox(height: 12), ShimmerSkeleton(height: 120), SizedBox(height: 10), ShimmerSkeleton(height: 90), SizedBox(height: 10), ShimmerSkeleton(height: 150), SizedBox(height: 10), ShimmerSkeleton(height: 150)]);
}
