import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'nexora_button.dart';

class NexoraDialog extends StatelessWidget {
  const NexoraDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Lanjut',
    this.cancelLabel = 'Batal',
    this.danger = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Lanjut',
    String cancelLabel = 'Batal',
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (context) => NexoraDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        danger: danger,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTypography.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            NexoraButton(
              label: confirmLabel,
              variant: danger ? NexoraButtonVariant.danger : NexoraButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            NexoraButton(
              label: cancelLabel,
              variant: NexoraButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class NexoraToast {
  const NexoraToast._();

  static void show(BuildContext context, String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
        backgroundColor: error ? AppColors.danger : AppColors.space800,
        behavior: SnackBarBehavior.floating,
        duration: AppMotion.chart,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
      ),
    );
  }
}
