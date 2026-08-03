import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class RecentTransactionCard extends StatelessWidget {
  const RecentTransactionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Transactions', style: AppTypography.heading3),

          AppSpacing.gapLG,

          const _Item(
            icon: Icons.fastfood_rounded,
            title: 'McDonald\'s',
            subtitle: 'Food',
            amount: '- \$24.50',
            color: AppColors.warning,
          ),

          AppSpacing.gapMD,

          const _Item(
            icon: Icons.shopping_bag_rounded,
            title: 'Uniqlo',
            subtitle: 'Shopping',
            amount: '- \$89.00',
            color: AppColors.primary,
          ),

          AppSpacing.gapMD,

          const _Item(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Salary',
            subtitle: 'Income',
            amount: '+ \$3,250',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .15),
            borderRadius: AppRadius.radiusLG,
          ),
          child: Icon(icon, color: color),
        ),

        AppSpacing.hGapMD,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyLarge),
              Text(subtitle, style: AppTypography.bodySmall),
            ],
          ),
        ),

        Text(amount, style: AppTypography.labelLarge),
      ],
    );
  }
}
