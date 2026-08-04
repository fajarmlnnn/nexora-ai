import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/recent_transaction_card.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final budgetAsync = ref.watch(budgetItemsProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final insightAsync = ref.watch(aiInsightProvider);

    return PremiumScaffold(
      child: summaryAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (error, stackTrace) => Padding(
          padding: AppSpacing.screen,
          child: EmptyStateCard(
            icon: LucideIcons.triangleAlert,
            title: 'Data belum tersedia',
            message: error.toString(),
            action: 'Coba Lagi',
          ),
        ),
        data: (summary) {
          return SingleChildScrollView(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardHeader(),
                AppSpacing.gapLG,
                BalanceCard(summary: summary),
                AppSpacing.gapLG,
                Row(
                  children: [
                    StatCard(
                      title: 'Income',
                      amount: rupiah(summary.monthlyIncome),
                      icon: LucideIcons.arrowDownLeft,
                      iconColor: AppColors.success,
                    ),
                    AppSpacing.hGapMD,
                    StatCard(
                      title: 'Expense',
                      amount: rupiah(summary.monthlyExpense),
                      icon: LucideIcons.arrowUpRight,
                      iconColor: AppColors.danger,
                    ),
                  ],
                ),
                AppSpacing.gapLG,
                insightAsync.when(
                  loading: () => const ShimmerSkeleton(height: 148),
                  error: (error, stackTrace) => EmptyStateCard(
                    icon: LucideIcons.bot,
                    title: 'Insight belum tersedia',
                    message: error.toString(),
                    action: 'Coba Lagi',
                  ),
                  data: (insight) => AIInsightCard(insight: insight),
                ),
                AppSpacing.gapLG,
                const _QuickActions(),
                AppSpacing.gapLG,
                const _SmartCommandCenter(),
                AppSpacing.gapLG,
                budgetAsync.when(
                  loading: () => const ShimmerSkeleton(height: 286),
                  error: (error, stackTrace) => EmptyStateCard(
                    icon: LucideIcons.triangleAlert,
                    title: 'Budget belum tersedia',
                    message: error.toString(),
                    action: 'Coba Lagi',
                  ),
                  data: (items) => BudgetSummaryCard(items: items),
                ),
                AppSpacing.gapMD,
                transactionsAsync.when(
                  loading: () => const ShimmerSkeleton(height: 190),
                  error: (error, stackTrace) => EmptyStateCard(
                    icon: LucideIcons.triangleAlert,
                    title: 'Transaksi belum tersedia',
                    message: error.toString(),
                    action: 'Coba Lagi',
                  ),
                  data: (transactions) => RecentTransactionCard(transactions: transactions),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Quick Action'),
        AppSpacing.gapMD,
        Row(
          children: const [
            _QuickAction(icon: LucideIcons.receiptText, label: 'Tambah\nTransaksi'),
            SizedBox(width: 10),
            _QuickAction(icon: LucideIcons.scanLine, label: 'Scan\nStruk'),
            SizedBox(width: 10),
            _QuickAction(icon: LucideIcons.walletCards, label: 'Buat\nBudget'),
            SizedBox(width: 10),
            _QuickAction(icon: LucideIcons.send, label: 'Transfer'),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PremiumEntrance(
        child: PremiumCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              PremiumIconBadge(icon: icon, color: AppColors.primaryLight, size: 42),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}


class _SmartCommandCenter extends StatelessWidget {
  const _SmartCommandCenter();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('AI Financial Command Center'),
        AppSpacing.gapMD,
        const Row(
          children: [
            Expanded(child: _ScoreCard(label: 'Budget Health', value: '82', caption: 'Sehat', color: AppColors.success)),
            SizedBox(width: 12),
            Expanded(child: _ScoreCard(label: 'Financial Score', value: '76', caption: '+8 bulan ini', color: AppColors.primaryLight)),
          ],
        ),
        AppSpacing.gapMD,
        const _InsightTile(
          icon: LucideIcons.calendarCheck,
          title: 'Ringkasan hari ini',
          message: 'Kamu mengeluarkan Rp 185.000 hari ini, 14% lebih rendah dari rata-rata harian minggu lalu.',
          color: AppColors.info,
        ),
        const _InsightTile(
          icon: LucideIcons.trendingDown,
          title: 'Spending trend membaik',
          message: 'Pengeluaran makanan turun 18%. Pertahankan batas Rp 120.000 per hari sampai akhir bulan.',
          color: AppColors.success,
        ),
        const _InsightTile(
          icon: LucideIcons.walletCards,
          title: 'Rekomendasi tabungan',
          message: 'Nexora memperkirakan kamu aman menabung Rp 750.000 tambahan bulan ini.',
          color: AppColors.primaryLight,
        ),
        const _InsightTile(
          icon: LucideIcons.receiptText,
          title: 'Tagihan mendatang',
          message: 'Internet rumah Rp 420.000 jatuh tempo 3 hari lagi. Saldo tetap aman setelah pembayaran.',
          color: AppColors.warning,
        ),
        const _InsightTile(
          icon: LucideIcons.badgeCheck,
          title: 'Achievement unlocked',
          message: 'Kamu berhasil menjaga cashflow positif selama 12 hari berturut-turut.',
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.label, required this.value, required this.caption, required this.color});

  final String label;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          AppSpacing.gapXS,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: double.parse(value)),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, animated, child) => Text(
                  animated.round().toString(),
                  style: AppTypography.heading1.copyWith(color: color),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('/100', style: AppTypography.caption),
              ),
            ],
          ),
          Text(caption, style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.icon, required this.title, required this.message, required this.color});

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            PremiumIconBadge(icon: icon, color: color, size: 42),
            AppSpacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLarge),
                  AppSpacing.gapXXS,
                  Text(message, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton(width: 180, height: 28),
          SizedBox(height: 18),
          ShimmerSkeleton(height: 206),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: ShimmerSkeleton(height: 118)),
              SizedBox(width: 14),
              Expanded(child: ShimmerSkeleton(height: 118)),
            ],
          ),
          SizedBox(height: 18),
          ShimmerSkeleton(height: 286),
          SizedBox(height: 18),
          ShimmerSkeleton(height: 180),
        ],
      ),
    );
  }
}
