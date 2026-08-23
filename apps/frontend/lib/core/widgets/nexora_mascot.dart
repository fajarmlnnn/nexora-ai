import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

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

/// Single Nexora mascot implementation. SVG master only.
class NexoraMascot extends StatelessWidget {
  const NexoraMascot({
    super.key,
    this.size = 180,
    this.state = NexoraMascotState.idle,
    this.animate = true,
  });

  final double size;
  final NexoraMascotState state;
  final bool animate;

  Color get _accent => switch (state) {
        NexoraMascotState.goal ||
        NexoraMascotState.growth ||
        NexoraMascotState.success =>
          AppColors.success,
        NexoraMascotState.security => AppColors.info,
        NexoraMascotState.warning => AppColors.warning,
        NexoraMascotState.thinking ||
        NexoraMascotState.analyzing =>
          AppColors.ai,
        NexoraMascotState.idle || NexoraMascotState.welcome => AppColors.brand,
      };

  @override
  Widget build(BuildContext context) {
    final mascot = Semantics(
      label: 'Maskot Nexora',
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: .16),
                blurRadius: size * .45,
                spreadRadius: size * .02,
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/mascot/nexora_mascot_master.svg',
            fit: BoxFit.contain,
          ),
        ),
      ),
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
