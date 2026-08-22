import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

/// Brand primitives for the Nexora 2.0 visual language.
///
/// Keep feature screens dependent on these semantic primitives instead of
/// inventing one-off purple/glow values.
abstract final class NexoraBrand {
  NexoraBrand._();

  static const Color background = AppColors.space950;
  static const Color backgroundSoft = AppColors.space900;
  static const Color surface = AppColors.space850;
  static const Color glass = AppColors.surfaceGlass;
  static const Color glassStrong = AppColors.surfaceGlassStrong;
  static const Color border = AppColors.borderGlass;
  static const Color focus = AppColors.borderFocus;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.brandPrimaryBright,
      AppColors.brandPrimary,
      AppColors.brandPrimaryDeep,
    ],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.brandMagenta,
      AppColors.brandPrimary,
      AppColors.brandSecondary,
    ],
  );

  static const BorderRadius cardRadius = AppRadius.radiusXL;
  static const BorderRadius sheetRadius = AppRadius.radiusXXL;
  static const BorderRadius controlRadius = AppRadius.radiusLG;
  static const BorderRadius pillRadius = AppRadius.radiusPill;

  static const double glassOpacity = 0.08;
  static const double strongGlassOpacity = 0.12;
  static const double disabledOpacity = AppMotion.disabledOpacity;

  static List<BoxShadow> get cardShadow => AppShadows.card;
  static List<BoxShadow> get floatingShadow => AppShadows.floating;
  static List<BoxShadow> get primaryGlow => AppShadows.glow;
}
