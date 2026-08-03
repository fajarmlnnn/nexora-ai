import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nexora AI Gradient System
abstract final class AppGradients {
  AppGradients._();

  // ===========================
  // Primary
  // ===========================

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
  );

  // ===========================
  // Balance Card
  // ===========================

  static const LinearGradient balanceCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
    stops: [0.0, 0.55, 1.0],
  );

  // ===========================
  // AI Card
  // ===========================

  static const LinearGradient aiCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.aiAccent, AppColors.primary],
  );

  // ===========================
  // Button
  // ===========================

  static const LinearGradient button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, AppColors.primaryLight],
  );

  // ===========================
  // Background
  // ===========================

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.background, AppColors.surface],
  );

  // ===========================
  // Status
  // ===========================

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.successLight, AppColors.success],
  );

  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.warningLight, AppColors.warning],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.dangerLight, AppColors.danger],
  );

  // ===========================
  // Glass
  // ===========================

  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x22FFFFFF), Color(0x08FFFFFF)],
  );
}
