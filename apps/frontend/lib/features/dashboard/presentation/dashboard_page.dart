import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money_input.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/financial_overview_controller.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transaction_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _refreshDashboard(WidgetRef ref) async {
    await Future.wait<void>([
      ref.read(financialTransactionStoreProvider.notifier).reload(),
      ref.read(walletProvider.notifier).refreshWallets(),
      ref.refresh(budgetItemsProvider.future),
    ]);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final budgetAsync = ref.watch(budgetItemsProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final insight = ref.watch(aiInsightProvider);
    final analytics = ref.watch(financialAnalyticsProvider);
    final snapshot = ref.watch(financialStateSnapshotProvider);
    final walletCount = ref.watch(walletCountProvider);

    return NexoraScaffold(
      body: summaryAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (_, __) => _DashboardErrorState(
          onRetry: () {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(recentTransactionsProvider);
            ref.invalidate(budgetItemsProvider);
          },
        ),
        data: (summary) => RefreshIndicator.adaptive(
          onRefresh: () => _refreshDashboard(ref),
          color: AppColors.brandBright,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const DashboardHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Aset likuid', style: AppTypography.overline),
                    const SizedBox(height: AppSpacing.xs),
                    BalanceCard(
                      summary: summary,
                      totalBalance: snapshot.liquidAssets,
                      onTap: () => context.push('/financial-overview'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _AssetStrip(
                      walletCount: walletCount,
                      totalAssets: snapshot.liquidAssets,
                      onTap: () => context.go('/wallet'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Bulan ini', style: AppTypography.overline),
                    const SizedBox(height: AppSpacing.xs),
                    _CashflowCard(analytics: analytics),
                    const SizedBox(height: AppSpacing.lg),
                    AIInsightCard(insight: insight, onTap: () => context.push('/ai')),
                    const SizedBox(height: AppSpacing.lg),
                    const NexoraSectionHeader(title: 'Aksi cepat'),
                    const SizedBox(height: AppSpacing.xs),
                    const QuickActions(),
                    const SizedBox(height: AppSpacing.lg),
                    NexoraSectionHeader(title: 'Anggaran', actionLabel: 'Lihat semua', onAction: () => context.push('/budget')),
                    const SizedBox(height: AppSpacing.xs),
                    budgetAsync.when(
                      loading: () => const NexoraSkeleton(height: 180),
                      error: (_, __) => NexoraEmpty(
                        error: true,
                        title: 'Anggaran belum dapat dimuat',
                        reason: 'Coba muat ulang data anggaran.',
                        onPressed: () => ref.invalidate(budgetItemsProvider),
                      ),
                      data: (items) => BudgetSummaryCard(items: items),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    NexoraSectionHeader(title: 'Transaksi terbaru', actionLabel: 'Lihat semua', onAction: () => context.go('/transactions')),
                    const SizedBox(height: AppSpacing.xs),
                    transactionsAsync.when(
                      loading: () => const NexoraSkeleton(height: 205),
                      error: (_, __) => NexoraEmpty(
                        error: true,
                        title: 'Transaksi belum dapat dimuat',
                        reason: 'Coba muat ulang daftar transaksi.',
                        onPressed: () => ref.invalidate(recentTransactionsProvider),
                      ),
                      data: (transactions) => RecentTransactionCard(transactions: transactions),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetStrip extends StatelessWidget {
  const _AssetStrip({required this.walletCount, required this.totalAssets, required this.onTap});
  final int walletCount;
  final double totalAssets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NexoraSurface(
      onTap: onTap,
      semanticLabel: 'Kelola wallet',
      compact: true,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.brandDeep),
            child: const Icon(LucideIcons.walletCards, color: AppColors.textPrimary, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$walletCount ${walletCount == 1 ? 'wallet' : 'wallet'} aktif', style: AppTypography.labelLarge),
                Text('Aset likuid ${rupiah(totalAssets)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _CashflowCard extends StatelessWidget {
  const _CashflowCard({required this.analytics});
  final FinancialAnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    final positive = analytics.netCashflow >= 0;
    final accent = positive ? AppColors.success : AppColors.danger;
    final rate = (analytics.savingsRate * 100).clamp(-999.0, 999.0);
    return NexoraSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Arus kas', style: AppTypography.labelLarge)),
              Text('${analytics.transactionCount} transaksi', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _Metric(icon: LucideIcons.arrowDownToLine, label: 'Pemasukan', value: analytics.income, color: AppColors.success)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _Metric(icon: LucideIcons.arrowUpFromLine, label: 'Pengeluaran', value: analytics.expense, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          NexoraSurface(
            compact: true,
            child: Row(
              children: [
                Icon(positive ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 16, color: accent),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text('Net cashflow', style: AppTypography.caption)),
                Semantics(
                  label: spokenRupiah(analytics.netCashflow),
                  child: Text(rupiah(analytics.netCashflow), style: AppTypography.labelMedium.copyWith(color: accent)),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text('${rate.toStringAsFixed(0)}%', style: AppTypography.caption.copyWith(color: accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NexoraSurface(
      compact: true,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                Semantics(
                  label: spokenRupiah(value),
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(rupiah(value), style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: NexoraEmpty(
          error: true,
          icon: LucideIcons.triangleAlert,
          title: 'Beranda belum siap',
          reason: 'Ada kendala saat mengambil data keuanganmu. Coba muat ulang.',
          onPressed: onRetry,
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
      padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexoraSkeleton(width: 160, height: 26),
          SizedBox(height: AppSpacing.lg),
          NexoraSkeleton(height: 220),
          SizedBox(height: AppSpacing.sm),
          NexoraSkeleton(height: 64),
          SizedBox(height: AppSpacing.lg),
          NexoraSkeleton(height: 160),
        ],
      ),
    );
  }
}
