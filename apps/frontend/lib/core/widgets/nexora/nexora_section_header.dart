import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_typography.dart';

class NexoraSectionHeader extends StatelessWidget {
  const NexoraSectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.heading3)),
        if (actionLabel != null && onAction != null)
          Semantics(
            button: true,
            label: actionLabel,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(actionLabel!, style: AppTypography.labelLarge.copyWith(color: AppColors.brandPrimaryBright)),
              ),
            ),
          ),
      ],
    );
  }

  static Widget animated({required String title, String? actionLabel, VoidCallback? onAction}) {
    return TweenAnimationBuilder<double>(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: NexoraSectionHeader(title: title, actionLabel: actionLabel, onAction: onAction),
    );
  }
}
