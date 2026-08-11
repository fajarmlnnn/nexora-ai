import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final budgetAsync = ref.watch(budgetItemsProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final insight = ref.watch(aiInsightProvider);
    final totalAssets = ref.watch(totalWalletBalanceProvider);

    return PremiumScaffold(
      child: summaryAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (error, stackTrace) => Padding(
          padding: AppSpacing.screen,
          child: _DashboardErrorState(
            title: 'Dashboard belum dapat dimuat',
            message: 'Terjadi kendala saat mengambil data keuanganmu.',
            onRetry: () => ref.invalidate(dashboardSummaryProvider),
          ),
        ),
        data: (summary) => SingleChildScrollView(
          padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PremiumEntrance(child: DashboardHeader()),
              AppSpacing.gapMD,
              PremiumEntrance(
                delay: const Duration(milliseconds: 50),
                child: BalanceCard(
                  summary: summary,
                  totalBalance: totalAssets,
                  onTap: () => context.push('/financial-overview'),
                ),
              ),
              AppSpacing.gapMD,
              PremiumEntrance(
                delay: const Duration(milliseconds: 150),
                child: AIInsightCard(insight: insight),
              ),
              AppSpacing.gapMD,
              const PremiumEntrance(
                delay: Duration(milliseconds: 200),
                child: QuickActions(),
              ),
              AppSpacing.gapMD,
              PremiumEntrance(
                delay: const Duration(milliseconds: 250),
                child: budgetAsync.when(
                  loading: () => const ShimmerSkeleton(height: 180),
                  error: (error, stackTrace) => _DashboardSectionError(
                    title: 'Budget belum tersedia',
                    onRetry: () => ref.invalidate(budgetItemsProvider),
                  ),
                  data: (items) => BudgetSummaryCard(items: items),
                ),
              ),
              AppSpacing.gapMD,
              PremiumEntrance(
                delay: const Duration(milliseconds: 300),
                child: transactionsAsync.when(
                  loading: () => const ShimmerSkeleton(height: 205),
                  error: (error, stackTrace) => _DashboardSectionError(
                    title: 'Transaksi belum tersedia',
                    onRetry: () => ref.invalidate(recentTransactionsProvider),
                  ),
                  data: (transactions) => RecentTransactionCard(transactions: transactions),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 15),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSectionError extends StatelessWidget {
  const _DashboardSectionError({required this.title, required this.onRetry});

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .055)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.triangleAlert,
              color: AppColors.warning,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Coba Lagi',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumEntrance(child: ShimmerSkeleton(width: 150, height: 26)),
            SizedBox(height: 18),
            PremiumEntrance(delay: Duration(milliseconds: 50), child: ShimmerSkeleton(height: 270)),
            SizedBox(height: 18),
            PremiumEntrance(delay: Duration(milliseconds: 150), child: ShimmerSkeleton(height: 150)),
            SizedBox(height: 18),
            PremiumEntrance(delay: Duration(milliseconds: 200), child: ShimmerSkeleton(height: 110)),
            SizedBox(height: 14),
            PremiumEntrance(delay: Duration(milliseconds: 300), child: ShimmerSkeleton(height: 190)),
          ],
        ),
      );
}
