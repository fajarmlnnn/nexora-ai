import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum NButtonVariant { primary, secondary, ghost, danger }

class NButton extends StatefulWidget {
  const NButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = NButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final NButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  State<NButton> createState() => _NButtonState();
}

class _NButtonState extends State<NButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      scale: _pressed ? AppMotion.pressedScale : 1,
      child: SizedBox(
        height: 56,
        width: widget.isExpanded ? double.infinity : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _gradient,
            color: _gradient == null ? _background : null,
            borderRadius: AppRadius.radiusLG,
            border: _border,
            boxShadow: widget.variant == NButtonVariant.primary
                ? AppShadows.button
                : AppShadows.none,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.radiusLG,
              onTap: _disabled ? null : widget.onPressed,
              onHighlightChanged: (value) {
                setState(() => _pressed = value);
              },
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: widget.isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          key: const ValueKey('content'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              widget.icon!,
                              AppSpacing.hGapSM,
                            ],
                            Text(
                              widget.label,
                              style: AppTypography.labelLarge.copyWith(
                                color: _textColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Opacity(
      opacity: _disabled ? AppMotion.disabledOpacity : 1,
      child: child,
    );
  }

  Gradient? get _gradient {
    if (_disabled) return null;

    switch (widget.variant) {
      case NButtonVariant.primary:
        return AppGradients.button;

      default:
        return null;
    }
  }

  Color get _background {
    switch (widget.variant) {
      case NButtonVariant.primary:
        return AppColors.primary;

      case NButtonVariant.secondary:
        return AppColors.surfaceVariant;

      case NButtonVariant.ghost:
        return Colors.transparent;

      case NButtonVariant.danger:
        return AppColors.danger;
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case NButtonVariant.primary:
      case NButtonVariant.danger:
        return AppColors.white;

      case NButtonVariant.secondary:
      case NButtonVariant.ghost:
        return AppColors.textPrimary;
    }
  }

  Border? get _border {
    switch (widget.variant) {
      case NButtonVariant.secondary:
      case NButtonVariant.ghost:
        return Border.all(color: AppColors.border);

      default:
        return null;
    }
  }
}
