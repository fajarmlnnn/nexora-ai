import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nexora AI Gradient System
abstract final class AppGradients {
  AppGradients._();

  // ==================================================
  // Primary
  // ==================================================

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
    stops: [0.0, .55, 1],
  );

  // ==================================================
  // Balance Card
  // ==================================================

  static const LinearGradient balanceCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B7BFF), AppColors.primary, Color(0xFF5131C9)],
    stops: [0, .45, 1],
  );

  // ==================================================
  // AI Card
  // ==================================================

  static const LinearGradient aiCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6D4AFF), Color(0xFF4C2DB8)],
  );

  // ==================================================
  // Button
  // ==================================================

  static const LinearGradient button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF6D4AFF), Color(0xFF8B5CF6)],
  );

  // ==================================================
  // Background
  // ==================================================

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF06080D), AppColors.background, Color(0xFF0D111A)],
    stops: [0, .55, 1],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.card, AppColors.cardSecondary],
  );

  // ==================================================
  // Success
  // ==================================================

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF54E38E), AppColors.success],
  );

  // ==================================================
  // Warning
  // ==================================================

  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD06A), AppColors.warning],
  );

  // ==================================================
  // Danger
  // ==================================================

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A7A), AppColors.danger],
  );

  // ==================================================
  // Glass
  // ==================================================

  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x18FFFFFF), Color(0x08FFFFFF)],
  );

  // ==================================================
  // Premium Dark
  // ==================================================

  static const LinearGradient premiumDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B0D14), Color(0xFF131826)],
  );
}
