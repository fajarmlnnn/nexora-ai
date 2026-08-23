import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';

class NexoraIconButton extends StatefulWidget {
  const NexoraIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.variant = NexoraIconButtonVariant.quiet,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final NexoraIconButtonVariant variant;
  final String? semanticLabel;

  @override
  State<NexoraIconButton> createState() => _NexoraIconButtonState();
}

enum NexoraIconButtonVariant { quiet, add }

class _NexoraIconButtonState extends State<NexoraIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final isAdd = widget.variant == NexoraIconButtonVariant.add;
    final child = AnimatedScale(
      scale: _pressed ? AppMotion.pressedScale : 1,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: isAdd ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isAdd ? null : AppRadius.radiusMD,
          gradient: isAdd
              ? const LinearGradient(colors: [AppColors.brandPrimaryBright, AppColors.brandPrimary, AppColors.brandPrimaryDeep])
              : null,
          color: isAdd ? null : AppColors.space800,
          border: isAdd ? null : Border.all(color: AppColors.borderGlass),
          boxShadow: isAdd ? AppShadows.button : AppShadows.none,
        ),
        child: Icon(widget.icon, size: 20, color: Colors.white),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: GestureDetector(
            onTap: widget.onPressed,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
            child: child,
          ),
        ),
      ),
    );
  }
}
