import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_shadows.dart';

/// Semantic states for the Nexora character.
///
/// The current master asset remains the safe fallback until the new mascot
/// expression pack is added. Screens can adopt semantic states now without
/// coupling themselves to asset filenames.
enum NexoraMascotState {
  idle,
  welcome,
  thinking,
  analyzing,
  goal,
  growth,
  security,
  success,
  warning,
}

class NexoraMascotStateView extends StatelessWidget {
  const NexoraMascotStateView({
    super.key,
    this.state = NexoraMascotState.idle,
    this.size = 72,
    this.animate = true,
    this.showGlow = true,
  });

  final NexoraMascotState state;
  final double size;
  final bool animate;
  final bool showGlow;

  Color get _accent {
    switch (state) {
      case NexoraMascotState.goal:
      case NexoraMascotState.growth:
      case NexoraMascotState.success:
        return AppColors.success;
      case NexoraMascotState.security:
        return AppColors.brandSecondary;
      case NexoraMascotState.warning:
        return AppColors.warning;
      case NexoraMascotState.thinking:
      case NexoraMascotState.analyzing:
        return AppColors.brandMagenta;
      case NexoraMascotState.idle:
      case NexoraMascotState.welcome:
        return AppColors.brandPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mascot = Container(
      width: size,
      height: size,
      decoration: showGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: .16),
                  blurRadius: size * .55,
                  spreadRadius: size * .02,
                ),
              ],
            )
          : null,
      child: SvgPicture.asset(
        'assets/mascot/nexora_mascot_master.svg',
        fit: BoxFit.contain,
      ),
    );

    if (!animate) return mascot;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .96, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.standard,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: mascot,
    );
  }
}
