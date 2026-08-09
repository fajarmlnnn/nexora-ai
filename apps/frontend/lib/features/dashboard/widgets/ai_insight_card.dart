import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, .55, 1.0],
          colors: [Color(0xFF090A12), Color(0xFF17112D), Color(0xFF3A1C72)],
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
                left: -38,
                bottom: -58,
                child: Container(
                  width: 165,
                  height: 165,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .26), blurRadius: 58, spreadRadius: 10)],
                  ),
                ),
              ),
              Positioned(
                right: -60,
                top: -70,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primaryLight.withValues(alpha: .10), blurRadius: 72, spreadRadius: 6)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 13, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 108,
                      height: 108,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 94,
                            height: 94,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [AppColors.primaryLight.withValues(alpha: .20), AppColors.primary.withValues(alpha: .015)]),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: -1.5, end: 1.5),
                            duration: const Duration(milliseconds: 2200),
                            curve: Curves.easeInOut,
                            builder: (context, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
                            child: SvgPicture.asset('assets/mascot/nexora_mascot_master.svg', width: 104, height: 104, fit: BoxFit.contain),
                          ),
                          Positioned(
                            right: -1,
                            top: 7,
                            child: Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: const Color(0xFF12101F),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primaryLight.withValues(alpha: .38)),
                                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .28), blurRadius: 11)],
                              ),
                              child: Icon(statusIcon, size: 12, color: AppColors.primaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primaryLight),
                            const SizedBox(width: 6),
                            Text('Nexora AI', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800, letterSpacing: .15)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .20), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.primaryLight.withValues(alpha: .20))),
                              child: Text('AI', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 9, fontWeight: FontWeight.w800)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text('Nexora AI Insight', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(insight.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: .72), height: 1.3)),
                          const SizedBox(height: 7),
                          Row(children: [Text('Lihat Insight', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)), const SizedBox(width: 4), const Icon(LucideIcons.arrowRight, size: 13, color: AppColors.primaryLight)]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.primaryLight),
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