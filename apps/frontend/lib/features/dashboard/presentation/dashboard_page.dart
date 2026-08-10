import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
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
          child: EmptyStateCard(
            icon: LucideIcons.triangleAlert,
            title: 'Data belum tersedia',
            message: error.toString(),
            action: 'Coba Lagi',
          ),
        ),
        data: (summary) => SingleChildScrollView(
          padding: AppSpacing.screen.copyWith(
            bottom: AppSpacing.bottomNav(context),
          ),
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
              AppSpacing.gapLG,
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
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : BudgetSummaryCard(items: items),
                ),
              ),
              AppSpacing.gapMD,
              PremiumEntrance(
                delay: const Duration(milliseconds: 300),
                child: transactionsAsync.when(
                  loading: () => const ShimmerSkeleton(height: 190),
                  error: (error, stackTrace) => EmptyStateCard(
                    icon: LucideIcons.triangleAlert,
                    title: 'Transaksi belum tersedia',
                    message: error.toString(),
                    action: 'Coba Lagi',
                  ),
                  data: (transactions) => RecentTransactionCard(
                    transactions: transactions,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: AppSpacing.screen.copyWith(
          bottom: AppSpacing.bottomNav(context),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumEntrance(child: ShimmerSkeleton(width: 150, height: 26)),
            SizedBox(height: 18),
            PremiumEntrance(
              delay: Duration(milliseconds: 50),
              child: ShimmerSkeleton(height: 270),
            ),
            SizedBox(height: 18),
            PremiumEntrance(
              delay: Duration(milliseconds: 150),
              child: ShimmerSkeleton(height: 150),
            ),
            SizedBox(height: 18),
            PremiumEntrance(
              delay: Duration(milliseconds: 200),
              child: ShimmerSkeleton(height: 110),
            ),
            SizedBox(height: 14),
            PremiumEntrance(
              delay: Duration(milliseconds: 300),
              child: ShimmerSkeleton(height: 190),
            ),
          ],
        ),
      );
}
