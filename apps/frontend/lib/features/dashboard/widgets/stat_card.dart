import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.radiusXL,
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .12),
                borderRadius: AppRadius.radiusLG,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),

            AppSpacing.gapMD,

            Text(title, style: AppTypography.bodySmall),

            AppSpacing.gapXS,

            Text(amount, style: AppTypography.heading3),
          ],
        ),
      ),
    );
  }
}
