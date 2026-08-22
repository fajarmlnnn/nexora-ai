import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../controllers/dashboard_controller.dart';
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
    final totalAssets = ref.watch(totalWalletBalanceProvider);
    final walletCount = ref.watch(walletCountProvider);

    return PremiumScaffold(
      child: summaryAsync.when(
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
          color: AppColors.primaryLight,
          backgroundColor: AppColors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const PremiumEntrance(child: DashboardHeader()),
                    const SizedBox(height: 18),
                    _SectionEyebrow(icon: LucideIcons.sparkles, label: 'FINANCIAL COMMAND CENTER'),
                    const SizedBox(height: 8),
                    PremiumEntrance(
                      delay: const Duration(milliseconds: 40),
                      child: BalanceCard(
                        summary: summary,
                        totalBalance: totalAssets,
                        onTap: () => context.push('/financial-overview'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PremiumEntrance(
                      delay: const Duration(milliseconds: 80),
                      child: _AssetStrip(walletCount: walletCount, totalAssets: totalAssets, onTap: () => context.go('/wallet')),
                    ),
                    const SizedBox(height: 18),
                    const _SectionEyebrow(icon: LucideIcons.activity, label: 'THIS MONTH'),
                    const SizedBox(height: 8),
                    PremiumEntrance(
                      delay: const Duration(milliseconds: 120),
                      child: _CashflowCard(analytics: analytics),
                    ),
                    const SizedBox(height: 18),
                    PremiumEntrance(
                      delay: const Duration(milliseconds: 160),
                      child: AIInsightCard(insight: insight),
                    ),
                    const SizedBox(height: 18),
                    const _SectionHeader(title: 'Quick actions', action: 'Fast & simple'),
                    const SizedBox(height: 8),
                    const PremiumEntrance(
                      delay: Duration(milliseconds: 200),
                      child: QuickActions(),
                    ),
                    const SizedBox(height: 18),
                    const _SectionHeader(title: 'Budget', action: 'Your limits'),
                    const SizedBox(height: 8),
                    PremiumEntrance(
                      delay: const Duration(milliseconds: 240),
                      child: budgetAsync.when(
                        loading: () => const ShimmerSkeleton(height: 180),
                        error: (_, __) => _InlineError(onRetry: () => ref.invalidate(budgetItemsProvider)),
                        data: (items) => BudgetSummaryCard(items: items),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      title: 'Recent transactions',
                      action: 'View all',
                      onTap: () => context.go('/transactions'),
                    ),
                    const SizedBox(height: 8),
                    PremiumEntrance(
                      delay: const Duration(milliseconds: 280),
                      child: transactionsAsync.when(
                        loading: () => const ShimmerSkeleton(height: 205),
                        error: (_, __) => _InlineError(onRetry: () => ref.invalidate(recentTransactionsProvider)),
                        data: (transactions) => RecentTransactionCard(transactions: transactions),
                      ),
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

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted, letterSpacing: 1.25, fontWeight: FontWeight.w800)),
        ],
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, this.onTap});
  final String title;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.heading4.copyWith(fontSize: 18, fontWeight: FontWeight.w800))),
          if (onTap != null)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(children: [Text(action, style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)), const SizedBox(width: 3), const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primaryLight)]),
              ),
            )
          else
            Text(action, style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      );
}

class _AssetStrip extends StatelessWidget {
  const _AssetStrip({required this.walletCount, required this.totalAssets, required this.onTap});
  final int walletCount;
  final double totalAssets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => NCard(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        showBorder: true,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)]), boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: .18), blurRadius: 16)]),
              child: const Icon(LucideIcons.walletCards, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$walletCount ${walletCount == 1 ? 'wallet' : 'wallets'} aktif', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Total aset ${rupiah(totalAssets)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ]),
            ),
            IconButton(onPressed: onTap, tooltip: 'Kelola wallet', icon: const Icon(LucideIcons.chevronRight, size: 18)),
          ],
        ),
      );
}

class _CashflowCard extends StatelessWidget {
  const _CashflowCard({required this.analytics});
  final FinancialAnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    final positive = analytics.netCashflow >= 0;
    final accent = positive ? AppColors.success : AppColors.danger;
    final rate = (analytics.savingsRate * 100).clamp(-999.0, 999.0);
    return NCard(
      padding: const EdgeInsets.all(14),
      showBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Cashflow overview', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800))),
          _TinyPill(label: '${analytics.transactionCount} transaksi', color: AppColors.primaryLight),
        ]),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(child: _Metric(icon: LucideIcons.arrowDownToLine, label: 'Income', value: analytics.income, color: AppColors.success)),
          const SizedBox(width: 9),
          Expanded(child: _Metric(icon: LucideIcons.arrowUpFromLine, label: 'Expense', value: analytics.expense, color: AppColors.danger)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: accent.withValues(alpha: .07), borderRadius: BorderRadius.circular(14), border: Border.all(color: accent.withValues(alpha: .12))),
          child: Row(children: [
            Icon(positive ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 16, color: accent),
            const SizedBox(width: 8),
            Expanded(child: Text('Net cashflow', style: AppTypography.caption.copyWith(color: AppColors.textSecondary))),
            Text(rupiah(analytics.netCashflow), style: AppTypography.labelMedium.copyWith(color: accent, fontWeight: FontWeight.w900)),
            const SizedBox(width: 7),
            Text('${rate.toStringAsFixed(0)}%', style: AppTypography.caption.copyWith(color: accent, fontWeight: FontWeight.w900)),
          ]),
        ),
      ]),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .025), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: .045))),
        child: Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withValues(alpha: .08), shape: BoxShape.circle), child: Icon(icon, size: 14, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(rupiah(value), style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w900, color: Colors.white))),
          ])),
        ]),
      );
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: .12))), child: Text(label, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w700)));
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => NCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), child: Row(children: [const Icon(LucideIcons.triangleAlert, color: AppColors.warning, size: 18), const SizedBox(width: 9), Expanded(child: Text('Bagian ini belum dapat dimuat.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary))), TextButton(onPressed: onRetry, child: const Text('Retry'))]));
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: AppSpacing.screen, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.danger.withValues(alpha: .08)), child: const Icon(LucideIcons.triangleAlert, color: AppColors.danger, size: 28)),
        const SizedBox(height: 14),
        Text('Dashboard belum siap', style: AppTypography.heading4.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Ada kendala saat mengambil data keuanganmu. Coba muat ulang.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(LucideIcons.refreshCw, size: 16), label: const Text('Coba Lagi')),
      ])));
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PremiumEntrance(child: ShimmerSkeleton(width: 160, height: 26)),
        SizedBox(height: 18),
        ShimmerSkeleton(height: 275),
        SizedBox(height: 12),
        ShimmerSkeleton(height: 66),
        SizedBox(height: 18),
        ShimmerSkeleton(height: 175),
        SizedBox(height: 18),
        ShimmerSkeleton(height: 150),
        SizedBox(height: 18),
        ShimmerSkeleton(height: 110),
        SizedBox(height: 18),
        ShimmerSkeleton(height: 190),
      ]));
}
