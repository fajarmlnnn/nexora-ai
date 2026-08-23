import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'nexora/nexora.dart';

/// Compact heuristic summary. Not the Laravel AI gateway.
class ContextAIInsight extends StatelessWidget {
  const ContextAIInsight({
    super.key,
    required this.message,
    this.title = 'Ringkasan',
    this.actionLabel = 'Tanya Nexora AI',
    this.onAction,
    this.compact = true,
  });

  final String message;
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return NexoraSurface(
      compact: compact,
      onTap: onAction ?? () => context.push('/ai'),
      semanticLabel: title,
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
                Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.ai)),
                const SizedBox(height: AppSpacing.xxs),
                Text(message, maxLines: compact ? 2 : 3, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                Text(actionLabel, style: AppTypography.caption.copyWith(color: AppColors.brandBright)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
