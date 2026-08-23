import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  AppGradients._();

  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.brandBright,
      AppColors.brand,
      AppColors.brandDeep,
    ],
    stops: [0.0, 0.48, 1.0],
  );

  static const LinearGradient auroraBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandCyan, AppColors.info, AppColors.brand],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient cosmicBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.canvas, AppColors.canvasElevated, AppColors.space800],
    stops: [0.0, 0.58, 1.0],
  );

  static const LinearGradient glassSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.glassStrong, AppColors.glass],
  );

  static const LinearGradient aiAurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.ai, AppColors.brand, AppColors.info],
    stops: [0.0, 0.52, 1.0],
  );

  static const LinearGradient primary = aurora;
  static const LinearGradient heroCard = cosmicBackground;
  static const LinearGradient nexoraBackground = cosmicBackground;
  static const LinearGradient background = cosmicBackground;
  static const LinearGradient balanceCard = aurora;
  static const LinearGradient aiCard = aiAurora;
  static const LinearGradient button = aurora;
  static const LinearGradient surface = glassSurface;
  static const LinearGradient glass = glassSurface;
  static const LinearGradient premiumDark = cosmicBackground;

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.success, AppColors.chart3],
  );

  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.warning, AppColors.chart4],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.danger, AppColors.chart5],
  );
}
