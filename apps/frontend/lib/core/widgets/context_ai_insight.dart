import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Compact AI surface for feature-specific financial guidance.
/// The feature supplies context; the visual identity stays consistent.
class ContextAIInsight extends StatelessWidget {
  const ContextAIInsight({
    super.key,
    required this.message,
    this.title = 'Nexora AI',
    this.actionLabel = 'Lihat saran',
    this.onAction,
    this.compact = false,
  });

  final String message;
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 68, maxHeight: 78),
        padding: const EdgeInsets.fromLTRB(9, 8, 10, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF080910), Color(0xFF17102C), Color(0xFF32155F)],
          ),
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: .13)),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .12), blurRadius: 24, spreadRadius: -8)],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .10),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .18), blurRadius: 18)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: SvgPicture.asset('assets/mascot/nexora_mascot_master.svg', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(LucideIcons.sparkles, size: 12, color: AppColors.primaryLight),
                    const SizedBox(width: 4),
                    Text(title, style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .18), borderRadius: AppRadius.radiusPill),
                      child: Text('AI', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: .74), height: 1.15)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(width: 30, height: 40, child: Center(child: Icon(LucideIcons.chevronRight, size: 19, color: AppColors.primaryLight))),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 12, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080910), Color(0xFF17102C), Color(0xFF32155F)],
        ),
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: .13)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .12), blurRadius: 24, spreadRadius: -8)],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: .10),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .20), blurRadius: 22)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: SvgPicture.asset('assets/mascot/nexora_mascot_master.svg', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(LucideIcons.sparkles, size: 13, color: AppColors.primaryLight),
                  const SizedBox(width: 5),
                  Text(title, style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .18), borderRadius: AppRadius.radiusPill),
                    child: Text('AI', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 8, fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: .74), height: 1.25)),
                const SizedBox(height: 5),
                GestureDetector(onTap: onAction, child: Text('$actionLabel  →', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
