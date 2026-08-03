import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Summary', style: AppTypography.heading3),

          AppSpacing.gapLG,

          _buildItem('Food', '\$680 / \$900', .76, AppColors.success),

          AppSpacing.gapMD,

          _buildItem('Transport', '\$420 / \$600', .70, AppColors.warning),

          AppSpacing.gapMD,

          _buildItem('Shopping', '\$930 / \$1000', .93, AppColors.danger),
        ],
      ),
    );
  }

  Widget _buildItem(String title, String value, double progress, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Text(title, style: AppTypography.bodyLarge),
            const Spacer(),
            Text(value, style: AppTypography.bodySmall),
          ],
        ),

        AppSpacing.gapXS,

        ClipRRect(
          borderRadius: AppRadius.radiusLG,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.divider,
          ),
        ),
      ],
    );
  }
}
