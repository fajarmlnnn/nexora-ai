import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../models/ai_insight.dart';

class AIInsightCard extends StatelessWidget {
  const AIInsightCard({super.key, required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, gradient) = switch (insight.level) {
      InsightLevel.positive => (LucideIcons.badgeCheck, AppGradients.success),
      InsightLevel.warning => (LucideIcons.triangleAlert, AppGradients.primary),
      InsightLevel.critical => (LucideIcons.circleAlert, AppGradients.danger),
    };

    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.radiusXL,
        boxShadow: AppShadows.glow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .14),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
              const NexoraRobot(size: 78),
              Positioned(
                right: 2,
                top: 2,
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

          AppSpacing.hGapMD,

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
                    color: Colors.white.withValues(alpha: .85),
                  ),
                ),

                AppSpacing.gapMD,

                Row(
                  children: [
                    const Text(
                      'Lihat analisis',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.arrowRight,
                      size: 16,
                      color: Colors.white.withValues(alpha: .9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
