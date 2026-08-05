import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';

import '../models/ai_insight.dart';

class AIInsightCard extends StatelessWidget {
  const AIInsightCard({super.key, required this.insight, this.onTap});

  final AIInsight insight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, gradient) = switch (insight.level) {
      InsightLevel.positive => (LucideIcons.badgeCheck, AppGradients.success),
      InsightLevel.warning => (LucideIcons.triangleAlert, AppGradients.primary),
      InsightLevel.critical => (LucideIcons.circleAlert, AppGradients.danger),
    };

    return NCard(
      onTap: onTap,
      gradient: gradient,
      showBorder: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'dashboard_ai_insight',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.shrink(),
                ),
                const NexoraRobot(size: 74),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: .72),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 15),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.hGapLG,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTypography.heading3.copyWith(color: Colors.white),
                ),

                AppSpacing.gapXS,

                Text(
                  insight.message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: .90),
                    height: 1.55,
                  ),
                ),

                AppSpacing.gapLG,

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Analisis',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      AppSpacing.hGapXS,
                      Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: Colors.white.withValues(alpha: .92),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
