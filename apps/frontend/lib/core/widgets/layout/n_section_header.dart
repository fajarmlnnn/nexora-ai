import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// ------------------------------------------------------------
/// Nexora Design System
/// Component : NSectionHeader
/// ------------------------------------------------------------
///
/// Standard section header used across the app.
///
/// Example:
///
/// NSectionHeader(
///   title: 'Recent Transactions',
///   actionLabel: 'See All',
///   onActionPressed: () {},
/// )
class NSectionHeader extends StatelessWidget {
  const NSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onActionPressed,
    this.padding,
  });

  final String title;
  final String? subtitle;

  final String? actionLabel;
  final IconData? actionIcon;

  final VoidCallback? onActionPressed;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heading3),
                if (subtitle != null) ...[
                  AppSpacing.gapXXS,
                  Text(subtitle!, style: AppTypography.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton.icon(
              onPressed: onActionPressed,
              icon: actionIcon != null
                  ? Icon(actionIcon, size: 18, color: AppColors.primary)
                  : const SizedBox.shrink(),
              label: Text(
                actionLabel!,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
