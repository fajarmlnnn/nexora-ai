import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background = AppColors.card,
    this.gradient,
    this.radius = 18,
    this.borderColor,
    this.glowColor,
    this.glow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Gradient? gradient;
  final double radius;
  final Color? borderColor;
  final Color? glowColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final accent = glowColor ?? AppColors.primary;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.primaryLight.withValues(alpha: .18),
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: .14),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.width,
    this.height = 46,
    this.gradient,
    this.background,
    this.radius = 16,
    this.glowColor,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Gradient? gradient;
  final Color? background;
  final double radius;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final accent = glowColor ?? AppColors.primary;
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : gradient,
          color: onPressed == null ? AppColors.cardMuted : background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: .16)),
          boxShadow: onPressed == null
              ? null
              : [BoxShadow(color: accent.withValues(alpha: .18), blurRadius: 16, offset: const Offset(0, 5))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onPressed,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
