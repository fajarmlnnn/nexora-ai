import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/premium_widgets.dart';

import '../controllers/dashboard_controller.dart';

import '../widgets/ai_insight_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_actions.dart';
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

        error: (error, stackTrace) {
          return Padding(
            padding: AppSpacing.screen,
            child: EmptyStateCard(
              icon: LucideIcons.triangleAlert,
              title: "Data belum tersedia",
              message: error.toString(),
              action: "Coba Lagi",
            ),
          );
        },

        data: (summary) {
          return SingleChildScrollView(
            padding: AppSpacing.screen.copyWith(
              bottom: AppSpacing.bottomNav(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PremiumEntrance(child: DashboardHeader()),

                AppSpacing.gapLG,

                PremiumEntrance(
                  delay: const Duration(milliseconds: 50),
                  child: BalanceCard(summary: summary),
                ),

                AppSpacing.gapLG,

                PremiumEntrance(
                  delay: const Duration(milliseconds: 100),
                  child: Row(
                    children: [
                      StatCard(
                        title: "Income",
                        amount: rupiah(summary.monthlyIncome),
                        icon: LucideIcons.arrowDownLeft,
                        iconColor: AppColors.success,
                      ),

                      AppSpacing.hGapMD,

                      StatCard(
                        title: "Expense",
                        amount: rupiah(summary.monthlyExpense),
                        icon: LucideIcons.arrowUpRight,
                        iconColor: AppColors.danger,
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapLG,

                PremiumEntrance(
                  delay: const Duration(milliseconds: 150),
                  child: insightAsync.when(
                    loading: () => const ShimmerSkeleton(height: 150),
                    error: (error, stackTrace) {
                      return EmptyStateCard(
                        icon: LucideIcons.bot,
                        title: "Insight belum tersedia",
                        message: error.toString(),
                        action: "Coba Lagi",
                      );
                    },
                    data: (insight) {
                      return AIInsightCard(insight: insight);
                    },
                  ),
                ),

                AppSpacing.gapMD,

                const PremiumEntrance(
                  delay: Duration(milliseconds: 200),
                  child: QuickActions(),
                ),

                AppSpacing.gapLG,

                PremiumEntrance(
                  delay: const Duration(milliseconds: 250),
                  child: budgetAsync.when(
                    loading: () => const ShimmerSkeleton(height: 280),
                    error: (error, stackTrace) {
                      return EmptyStateCard(
                        icon: LucideIcons.triangleAlert,
                        title: "Budget belum tersedia",
                        message: error.toString(),
                        action: "Coba Lagi",
                      );
                    },
                    data: (items) {
                      return BudgetSummaryCard(items: items);
                    },
                  ),
                ),

                AppSpacing.gapLG,

                PremiumEntrance(
                  delay: const Duration(milliseconds: 300),
                  child: transactionsAsync.when(
                    loading: () => const ShimmerSkeleton(height: 220),
                    error: (error, stackTrace) {
                      return EmptyStateCard(
                        icon: LucideIcons.triangleAlert,
                        title: "Transaksi belum tersedia",
                        message: error.toString(),
                        action: "Coba Lagi",
                      );
                    },
                    data: (transactions) {
                      return RecentTransactionCard(transactions: transactions);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screen.copyWith(
        bottom: AppSpacing.bottomNav(context),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumEntrance(child: ShimmerSkeleton(width: 170, height: 30)),

          SizedBox(height: 22),

          PremiumEntrance(
            delay: Duration(milliseconds: 50),
            child: ShimmerSkeleton(height: 190),
          ),

          SizedBox(height: 18),

          PremiumEntrance(
            delay: Duration(milliseconds: 100),
            child: Row(
              children: [
                Expanded(child: ShimmerSkeleton(height: 88)),

                SizedBox(width: 12),

                Expanded(child: ShimmerSkeleton(height: 88)),
              ],
            ),
          ),

          SizedBox(height: 18),

          PremiumEntrance(
            delay: Duration(milliseconds: 150),
            child: ShimmerSkeleton(height: 145),
          ),

          SizedBox(height: 18),

          PremiumEntrance(
            delay: Duration(milliseconds: 200),
            child: ShimmerSkeleton(height: 110),
          ),

          SizedBox(height: 18),

          PremiumEntrance(
            delay: Duration(milliseconds: 250),
            child: ShimmerSkeleton(height: 270),
          ),

          SizedBox(height: 18),

          PremiumEntrance(
            delay: Duration(milliseconds: 300),
            child: ShimmerSkeleton(height: 240),
          ),
        ],
      ),
    );
  }
}
