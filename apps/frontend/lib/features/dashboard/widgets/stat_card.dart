import 'package:flutter/material.dart';

import '../../../core/theme/app_gradients.dart';
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
      child: Hero(
        tag: "stat_$title",
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.radiusXL,
            onTap: () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.surface,
                borderRadius: AppRadius.radiusXL,
                border: Border.all(color: Colors.white.withValues(alpha: .06)),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: .18),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 21),
                  ),

                  AppSpacing.hGapMD,

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.trending_up_rounded,
                                size: 12,
                                color: iconColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          amount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
