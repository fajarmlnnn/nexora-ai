import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/dashboard_bottom_nav.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/recent_transaction_card.dart';
import '../widgets/stat_card.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    final budgetAsync = ref.watch(budgetItemsProvider);

    final transactionsAsync = ref.watch(recentTransactionsProvider);

    final aiInsightAsync = ref.watch(aiInsightProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (error, stackTrace) => Center(child: Text(error.toString())),

          data: (summary) {
            return SingleChildScrollView(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(),

                  AppSpacing.gapXL,

                  BalanceCard(summary: summary),

                  AppSpacing.gapLG,

                  Row(
                    children: [
                      StatCard(
                        title: 'Income',
                        amount: '\$${summary.monthlyIncome.toStringAsFixed(0)}',
                        icon: LucideIcons.arrowDownLeft,
                        iconColor: AppColors.success,
                      ),

                      AppSpacing.hGapMD,

                      StatCard(
                        title: 'Expense',
                        amount:
                            '\$${summary.monthlyExpense.toStringAsFixed(0)}',
                        icon: LucideIcons.arrowUpRight,
                        iconColor: AppColors.danger,
                      ),
                    ],
                  ),

                  AppSpacing.gapLG,

                  budgetAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Text(error.toString()),
                    data: (items) => BudgetSummaryCard(items: items),
                  ),

                  AppSpacing.gapLG,

                  aiInsightAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Text(error.toString()),
                    data: (insight) => AIInsightCard(insight: insight),
                  ),

                  AppSpacing.gapLG,

                  transactionsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Text(error.toString()),
                    data: (transactions) =>
                        RecentTransactionCard(transactions: transactions),
                  ),

                  AppSpacing.gapLG,

                  DashboardBottomNav(
                    currentIndex: 0,
                    onTap: (index) {
                      switch (index) {
                        case 0:
                          context.go('/');
                          break;
                        case 1:
                          context.go('/transactions');
                          break;
                        case 3:
                          context.go('/profile');
                          break;
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
