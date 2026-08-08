import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nexora AI Shadow System
abstract final class AppShadows {
  AppShadows._();

  // ==================================================
  // None
  // ==================================================

  static const List<BoxShadow> none = [];

  // ==================================================
  // Text
  // ==================================================

  static final Shadow textShadow = Shadow(
    color: Colors.black.withValues(alpha: .22),
    blurRadius: 12,
    offset: const Offset(0, 2),
  );

  // ==================================================
  // Soft
  // ==================================================

  static final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .12),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  // ==================================================
  // Card
  // ==================================================

  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .30),
      blurRadius: 36,
      spreadRadius: -8,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: .05),
      blurRadius: 34,
      spreadRadius: -10,
      offset: const Offset(0, 8),
    ),
  ];

  // ==================================================
  // Floating
  // ==================================================

  static final List<BoxShadow> floating = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .28),
      blurRadius: 36,
      spreadRadius: -6,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: .05),
      blurRadius: 26,
      spreadRadius: -8,
      offset: const Offset(0, 6),
    ),
  ];

  // ==================================================
  // Glow
  // ==================================================

  static final List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: .18),
      blurRadius: 50,
      spreadRadius: 2,
    ),
  ];

  // ==================================================
  // Button
  // ==================================================

  static final List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: .30),
      blurRadius: 30,
      spreadRadius: -2,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: .20),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ==================================================
  // Modal
  // ==================================================

  static final List<BoxShadow> modal = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .42),
      blurRadius: 48,
      spreadRadius: -8,
      offset: const Offset(0, 24),
    ),
  ];

  // ==================================================
  // Premium Glow
  // ==================================================

  static final List<BoxShadow> premiumGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: .12),
      blurRadius: 60,
      spreadRadius: 8,
    ),
  ];

  // ==================================================
  // Success Glow
  // ==================================================

  static final List<BoxShadow> successGlow = [
    BoxShadow(
      color: AppColors.success.withValues(alpha: .18),
      blurRadius: 36,
      spreadRadius: 2,
    ),
  ];

  // ==================================================
  // Danger Glow
  // ==================================================

  static final List<BoxShadow> dangerGlow = [
    BoxShadow(
      color: AppColors.danger.withValues(alpha: .18),
      blurRadius: 36,
      spreadRadius: 2,
    ),
  ];
}
