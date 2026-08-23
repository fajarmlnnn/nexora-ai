import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_typography.dart';

class NexoraButton extends StatefulWidget {
  const NexoraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = NexoraButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final NexoraButtonVariant variant;
  final bool loading;
  final bool expand;
  final String? semanticLabel;

  @override
  State<NexoraButton> createState() => _NexoraButtonState();
}

enum NexoraButtonVariant { primary, secondary, ghost, danger }

class _NexoraButtonState extends State<NexoraButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final isPrimary = widget.variant == NexoraButtonVariant.primary;
    final isDanger = widget.variant == NexoraButtonVariant.danger;

    final decoration = switch (widget.variant) {
      NexoraButtonVariant.primary => BoxDecoration(
          gradient: AppGradients.aurora,
          borderRadius: AppRadius.radiusLG,
          boxShadow: AppShadows.button,
        ),
      NexoraButtonVariant.secondary => BoxDecoration(
          color: AppColors.space800,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: AppColors.borderGlass),
        ),
      NexoraButtonVariant.ghost => BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: AppColors.borderGlass),
        ),
      NexoraButtonVariant.danger => BoxDecoration(
          color: AppColors.danger,
          borderRadius: AppRadius.radiusLG,
        ),
    };

    final foreground = isPrimary || isDanger ? Colors.white : AppColors.textPrimary;
    final child = AnimatedScale(
      scale: _pressed ? AppMotion.pressedScale : 1,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: decoration,
        child: Center(
          child: widget.loading
              ? Semantics(liveRegion: true, label: 'Menyimpan', child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: foreground)))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
                    Text(widget.label, style: AppTypography.labelLarge.copyWith(color: foreground)),
                  ],
                ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTap: enabled ? widget.onPressed : null,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          child: widget.expand ? SizedBox(width: double.infinity, child: child) : child,
        ),
      ),
    );
  }
}
