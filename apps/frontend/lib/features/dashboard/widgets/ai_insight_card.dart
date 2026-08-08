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

      InsightLevel.warning => (LucideIcons.sparkles, AppGradients.primary),

      InsightLevel.critical => (LucideIcons.triangleAlert, AppGradients.danger),
    };

    return Hero(
      tag: "dashboard_ai_card",
      child: NCard(
        onTap: onTap,
        gradient: gradient,
        showBorder: false,
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .05),
                ),
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: "dashboard_ai_robot",
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: .10),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .12),
                        ),
                      ),

                      const NexoraRobot(size: 56),

                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: .82),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      AppSpacing.gapXS,

                      Text(
                        insight.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: .90),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "AI Insight",
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                LucideIcons.arrowRight,
                                size: 13,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
