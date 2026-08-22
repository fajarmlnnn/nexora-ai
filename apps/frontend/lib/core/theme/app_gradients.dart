import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  AppGradients._();

  // Nexora 2.0 brand gradients.
  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.brandPrimaryBright,
      AppColors.brandPrimary,
      AppColors.brandPrimaryDeep,
    ],
    stops: [0.0, 0.48, 1.0],
  );

  static const LinearGradient auroraBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandCyan, AppColors.brandSecondary, AppColors.brandPrimary],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient cosmicBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.space950, AppColors.space900, Color(0xFF100A24)],
    stops: [0.0, 0.58, 1.0],
  );

  static const LinearGradient glassSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceGlassStrong, AppColors.surfaceGlass],
  );

  static const LinearGradient aiAurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandMagenta, AppColors.brandPrimary, AppColors.brandSecondary],
    stops: [0.0, 0.52, 1.0],
  );

  // Legacy gradients kept for incremental migration.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
    stops: [0.0, .55, 1],
  );

  static const LinearGradient heroCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF170F48), Color(0xFF120C35), Color(0xFF09091C)],
    stops: [0.0, .56, 1.0],
  );

  static const LinearGradient nexoraBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.nexoraBackgroundEdge, AppColors.background, Color(0xFF07071A)],
    stops: [0.0, .52, 1.0],
  );

  static const LinearGradient background = nexoraBackground;

  static const LinearGradient balanceCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B7BFF), AppColors.primary, Color(0xFF351D83)],
    stops: [0, .45, 1],
  );

  static const LinearGradient aiCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E5FF6), Color(0xFF4D25B1), Color(0xFF21105B)],
  );

  static const LinearGradient button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.sendButton, AppColors.aiAccent],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.card, AppColors.cardSecondary],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF54E38E), AppColors.success],
  );

  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD06A), AppColors.warning],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A7A), AppColors.danger],
  );

  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x18FFFFFF), Color(0x08FFFFFF)],
  );

  static const LinearGradient premiumDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF00010A), Color(0xFF0A0A1F)],
  );
}
