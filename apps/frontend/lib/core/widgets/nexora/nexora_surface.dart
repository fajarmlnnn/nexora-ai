import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';

class NexoraSurface extends StatefulWidget {
  const NexoraSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.variant = NexoraSurfaceVariant.plain,
    this.compact = false,
    this.onTap,
    this.enabled = true,
    this.border = true,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final NexoraSurfaceVariant variant;
  final bool compact;
  final VoidCallback? onTap;
  final bool enabled;
  final bool border;
  final String? semanticLabel;

  @override
  State<NexoraSurface> createState() => _NexoraSurfaceState();
}

enum NexoraSurfaceVariant { plain, glass, hero }

class _NexoraSurfaceState extends State<NexoraSurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || !widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isHero = widget.variant == NexoraSurfaceVariant.hero;
    final background = switch (widget.variant) {
      NexoraSurfaceVariant.plain => AppColors.space850,
      NexoraSurfaceVariant.glass => AppColors.surfaceGlass,
      NexoraSurfaceVariant.hero => AppColors.space850,
    };

    final content = AnimatedScale(
      scale: _pressed ? AppMotion.pressedScale : 1,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: Container(
        width: double.infinity,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: isHero ? AppRadius.radiusXL : (widget.compact ? AppRadius.radiusLG : AppRadius.radiusXL),
          border: widget.border ? Border.all(color: AppColors.borderGlass) : null,
          boxShadow: isHero ? AppShadows.card : AppShadows.none,
        ),
        child: widget.child,
      ),
    );

    final interactive = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: content,
    );

    final result = widget.onTap != null
        ? Semantics(button: true, enabled: widget.enabled, label: widget.semanticLabel, child: interactive)
        : widget.semanticLabel == null
            ? content
            : Semantics(label: widget.semanticLabel, child: content);

    return Opacity(opacity: widget.enabled ? 1 : 0.45, child: result);
  }
}
