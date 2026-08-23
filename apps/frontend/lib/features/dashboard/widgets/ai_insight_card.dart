import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../models/ai_insight.dart';

class AIInsightCard extends StatelessWidget {
  const AIInsightCard({super.key, required this.insight, this.onTap});

  final AIInsight insight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NexoraSurface(
      onTap: onTap ?? () => context.push('/ai'),
      semanticLabel: insight.title,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.ai.withValues(alpha: .12),
              borderRadius: AppRadius.radiusMD,
            ),
            child: const Icon(LucideIcons.chartNoAxesCombined, color: AppColors.ai, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: AppTypography.labelLarge.copyWith(color: AppColors.ai)),
                const SizedBox(height: AppSpacing.xxs),
                Text(insight.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                Text('Tanya Nexora AI', style: AppTypography.caption.copyWith(color: AppColors.brandBright)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
