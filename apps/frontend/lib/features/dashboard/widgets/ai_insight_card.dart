import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../models/ai_insight.dart';
import 'nexora_ai_mascot.dart';

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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF27245B), Color(0xFF34266D), Color(0xFF201B4A)],
        ),
        color: AppColors.card,
        showBorder: true,
        showShadow: true,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: AppRadius.radiusXXL,
          child: Stack(
            children: [
              Positioned(
                left: -42,
                bottom: -54,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .22),
                        blurRadius: 52,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 92,
                      height: 104,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primaryLight.withValues(alpha: .20),
                                  AppColors.primary.withValues(alpha: .03),
                                ],
                              ),
                            ),
                          ),
                          const NexoraAIMascot(size: 94),
                          Positioned(
                            right: 1,
                            top: 8,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25204E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryLight.withValues(alpha: .35),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: .25),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                statusIcon,
                                size: 12,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
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
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.primaryLight.withValues(alpha: .18),
                                  ),
                                ),
                                child: Text(
                                  'AI',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryLight,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nexora AI Insight',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            insight.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: .68),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Text(
                                'Lihat Insight',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w800,
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
