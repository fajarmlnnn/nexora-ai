import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/dashboard_controller.dart';
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
