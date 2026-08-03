import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_transaction_card.dart';
import '../widgets/dashboard_bottom_nav.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardHeader(),

              AppSpacing.gapXL,

              const BalanceCard(),

              AppSpacing.gapLG,

              const Row(
                children: [
                  StatCard(
                    title: 'Income',
                    amount: '\$8,240',
                    icon: Icons.south_west_rounded,
                    iconColor: AppColors.success,
                  ),
                  AppSpacing.hGapMD,
                  StatCard(
                    title: 'Expense',
                    amount: '\$2,150',
                    icon: Icons.north_east_rounded,
                    iconColor: AppColors.danger,
                  ),
                ],
              ),

              AppSpacing.gapLG,

              const BudgetSummaryCard(),

              AppSpacing.gapLG,

              const AIInsightCard(),

              AppSpacing.gapLG,

              const RecentTransactionCard(),

              AppSpacing.gapLG,

              const DashboardBottomNav(),
            ],
          ),
        ),
      ),
    );
  }
}
