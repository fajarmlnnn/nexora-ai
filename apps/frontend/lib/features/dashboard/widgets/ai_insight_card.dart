import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
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
    final statusIcon = switch (insight.level) {
      InsightLevel.positive => LucideIcons.badgeCheck,
      InsightLevel.warning => LucideIcons.sparkles,
      InsightLevel.critical => LucideIcons.triangleAlert,
    };

    return Hero(
      tag: 'dashboard_ai_card',
      child: NCard(
        onTap: onTap,
        color: AppColors.card,
        showBorder: true,
        showShadow: true,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: 'dashboard_ai_robot',
              child: _RobotBadge(statusIcon: statusIcon),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        size: 14,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nexora AI',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .15,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    insight.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    insight.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _InsightAction(onTap: onTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotBadge extends StatelessWidget {
  const _RobotBadge({required this.statusIcon});

  final IconData statusIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: .06),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .14),
              ),
            ),
          ),

          const NexoraRobot(size: 46),

          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .22),
                ),
              ),
              child: Icon(statusIcon, size: 10, color: AppColors.primaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightAction extends StatelessWidget {
  const _InsightAction({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: AppColors.primary.withValues(alpha: .10),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat Insight',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.arrowRight,
                size: 13,
                color: AppColors.primaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
