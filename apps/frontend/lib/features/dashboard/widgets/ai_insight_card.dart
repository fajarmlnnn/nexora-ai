import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../models/ai_insight.dart';
import 'nexora_ai_mascot.dart';

/// A single, recognisable AI surface shared by the Home experience.
///
/// The card intentionally combines the mascot, AI state and the actual
/// insight copy so Nexora feels like one product rather than a collection
/// of unrelated cards.
class AIInsightCard extends StatelessWidget {
  const AIInsightCard({super.key, required this.insight, this.onTap});

  final AIInsight insight;
  final VoidCallback? onTap;

  Color get _accent => switch (insight.level) {
        InsightLevel.positive => AppColors.success,
        InsightLevel.warning => AppColors.warning,
        InsightLevel.critical => AppColors.danger,
      };

  IconData get _statusIcon => switch (insight.level) {
        InsightLevel.positive => LucideIcons.trendingUp,
        InsightLevel.warning => LucideIcons.triangleAlert,
        InsightLevel.critical => LucideIcons.shieldAlert,
      };

  String get _statusLabel => switch (insight.level) {
        InsightLevel.positive => 'HEALTHY SIGNAL',
        InsightLevel.warning => 'WATCH THIS',
        InsightLevel.critical => 'NEEDS ATTENTION',
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusXXL,
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B0916), Color(0xFF17102C), Color(0xFF2A1550)],
            ),
            borderRadius: AppRadius.radiusXXL,
            border: Border.all(color: _accent.withValues(alpha: .16)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .14),
                blurRadius: 28,
                spreadRadius: -10,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -24,
                top: -28,
                child: IgnorePointer(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _accent.withValues(alpha: .18),
                          _accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: .13),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryLight.withValues(alpha: .16),
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.sparkles,
                                  size: 14,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'NEXORA INTELLIGENCE',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryLight,
                                  letterSpacing: 1.05,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nexora AI Insight',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.heading3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            insight.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: .72),
                              height: 1.38,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: .09),
                                  borderRadius: AppRadius.radiusPill,
                                  border: Border.all(color: _accent.withValues(alpha: .14)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_statusIcon, size: 12, color: _accent),
                                    const SizedBox(width: 5),
                                    Text(
                                      _statusLabel,
                                      style: AppTypography.caption.copyWith(
                                        color: _accent,
                                        fontSize: 8,
                                        letterSpacing: .55,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (onTap != null)
                                Text(
                                  'Buka AI  →',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: .76),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      height: 126,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accent.withValues(alpha: .06),
                              border: Border.all(color: _accent.withValues(alpha: .13)),
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withValues(alpha: .20),
                                  blurRadius: 26,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 2,
                            child: NexoraAIMascot(
                              size: 112,
                              accent: _accent,
                              state: insight.level == InsightLevel.positive
                                  ? NexoraMascotVisualState.positive
                                  : insight.level == InsightLevel.warning
                                      ? NexoraMascotVisualState.warning
                                      : NexoraMascotVisualState.critical,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF090814).withValues(alpha: .92),
                                borderRadius: AppRadius.radiusPill,
                                border: Border.all(color: Colors.white.withValues(alpha: .08)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'ANALYZING',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white.withValues(alpha: .70),
                                      fontSize: 7.5,
                                      letterSpacing: .7,
                                      fontWeight: FontWeight.w800,
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
