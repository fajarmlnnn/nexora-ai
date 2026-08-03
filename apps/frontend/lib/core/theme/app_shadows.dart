import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nexora AI Shadow System
abstract final class AppShadows {
  AppShadows._();

  // ===========================
  // None
  // ===========================

  static const List<BoxShadow> none = [];

  // ===========================
  // Text
  // ===========================

  static final Shadow textShadow = Shadow(
    color: Colors.black.withValues(alpha: .18),
    blurRadius: 10,
    offset: const Offset(0, 2),
  );

  // ===========================
  // Soft
  // ===========================

  static final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ===========================
  // Card
  // ===========================

  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .14),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // ===========================
  // Floating
  // ===========================

  static final List<BoxShadow> floating = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .20),
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
  ];

  // ===========================
  // Glow
  // ===========================

  static final List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: .28),
      blurRadius: 40,
      spreadRadius: 2,
      offset: const Offset(0, 10),
    ),
  ];

  // ===========================
  // Button
  // ===========================

  static final List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: .25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ===========================
  // Modal
  // ===========================

  static final List<BoxShadow> modal = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .30),
      blurRadius: 36,
      offset: const Offset(0, 20),
    ),
  ];
}
