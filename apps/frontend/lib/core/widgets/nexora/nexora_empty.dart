import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import 'nexora_button.dart';
import 'nexora_surface.dart';

class NexoraEmpty extends StatelessWidget {
  const NexoraEmpty({
    super.key,
    required this.title,
    required this.reason,
    this.onPressed,
    this.ctaLabel,
    this.icon = LucideIcons.inbox,
    this.error = false,
    this.retryLabel = 'Coba lagi',
  });

  final String title;
  final String reason;
  final VoidCallback? onPressed;
  final String? ctaLabel;
  final IconData icon;
  final bool error;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final content = NexoraSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: error ? AppColors.danger.withValues(alpha: .10) : AppColors.surfaceGlass, borderRadius: AppRadius.radiusMD, border: Border.all(color: AppColors.borderGlass)),
            child: Icon(icon, size: 24, color: error ? AppColors.danger : AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: AppTypography.heading3),
          const SizedBox(height: 6),
          Text(reason, textAlign: TextAlign.center, style: AppTypography.bodySmall),
          if (onPressed != null && (ctaLabel != null || error)) ...[
            const SizedBox(height: 16),
            NexoraButton(label: error ? retryLabel : ctaLabel!, onPressed: onPressed, expand: false, variant: error ? NexoraButtonVariant.secondary : NexoraButtonVariant.primary),
          ],
        ],
      ),
    );

    return Semantics(
      container: true,
      label: title,
      child: TweenAnimationBuilder<double>(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 8 * (1 - value)), child: child)),
        child: content,
      ),
    );
  }
}
