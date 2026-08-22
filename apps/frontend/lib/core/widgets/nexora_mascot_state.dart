import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Semantic states for the Nexora character.
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
  const NexoraMascotStateView({super.key, this.state = NexoraMascotState.idle, this.size = 72, this.animate = true, this.showGlow = true});
  final NexoraMascotState state;
  final double size;
  final bool animate;
  final bool showGlow;

  Color get _accent => switch (state) {
    NexoraMascotState.goal || NexoraMascotState.growth || NexoraMascotState.success => AppColors.success,
    NexoraMascotState.security => AppColors.brandSecondary,
    NexoraMascotState.warning => AppColors.warning,
    NexoraMascotState.thinking || NexoraMascotState.analyzing => AppColors.brandMagenta,
    NexoraMascotState.idle || NexoraMascotState.welcome => AppColors.brandPrimary,
  };

  @override
  Widget build(BuildContext context) {
    final mascot = Container(
      width: size,
      height: size,
      decoration: showGlow ? BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: _accent.withValues(alpha: .16), blurRadius: size * .55, spreadRadius: size * .02)]) : null,
      child: SvgPicture.asset('assets/mascot/nexora_mascot_master.svg', fit: BoxFit.contain),
    );
    if (!animate) return mascot;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .96, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.standard,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: mascot,
    );
  }
}
