import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class TransactionEmptyState extends StatelessWidget {
  const TransactionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.receiptText,
            color: AppColors.textMuted,
            size: 44,
          ),
          AppSpacing.gapMD,
          Text('No transactions found', style: AppTypography.heading3),
          AppSpacing.gapXS,
          Text(
            'Try adjusting your search or filters.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
