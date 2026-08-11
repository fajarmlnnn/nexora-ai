import 'package:flutter/material.dart';

/// Nexora AI Color System
abstract final class AppColors {
  AppColors._();

  // ==================================================
  // Brand
  // ==================================================

  static const primary = Color(0xFF7C4DFF);
  static const primaryLight = Color(0xFFA78BFA);
  static const primaryDark = Color(0xFF5B35D5);

  static const aiAccent = Color(0xFF8B5CF6);

  // ==================================================
  // Background
  // ==================================================

  static const background = Color(0xFF090B11);

  static const surface = Color(0xFF111522);

  static const surfaceVariant = Color(0xFF171C2C);

  // Global application card surface.
  // Keep cards close to the Total Balance visual language:
  // dark/navy, restrained, and neutral so accent colors remain semantic.
  static const card = Color(0xFF12121C);

  static const cardSecondary = Color(0xFF171525);

  // ==================================================
  // Text
  // ==================================================

  static const textPrimary = Colors.white;

  static const textSecondary = Color(0xFFA8B0C3);

  static const textMuted = Color(0xFF6C7388);

  static const textDisabled = Color(0xFF4D5568);

  // ==================================================
  // Status
  // ==================================================

  static const success = Color(0xFF36D977);

  static const successLight = Color(0xFF56E08A);

  static const warning = Color(0xFFFFB648);

  static const warningLight = Color(0xFFFFC96B);

  static const danger = Color(0xFFFF5A5A);

  static const dangerLight = Color(0xFFFF7B7B);

  static const info = Color(0xFF38BDF8);

  // ==================================================
  // Charts
  // ==================================================

  static const chartPurple = Color(0xFF8B5CF6);

  static const chartBlue = Color(0xFF4F8CFF);

  static const chartGreen = Color(0xFF36D977);

  static const chartOrange = Color(0xFFFFB648);

  static const chartRed = Color(0xFFFF5A5A);

  // ==================================================
  // Border
  // ==================================================

  static const border = Color(0xFF2A3044);

  static const divider = Color(0xFF23293B);

  // ==================================================
  // Overlay
  // ==================================================

  static const overlay = Color(0x88000000);

  static const glass = Color(0x14FFFFFF);

  // ==================================================
  // Extra Surface
  // ==================================================

  static const elevated = Color(0xFF20263A);

  static const hover = Color(0xFF252D43);

  static const pressed = Color(0xFF2B3550);

  // ==================================================
  // Utility
  // ==================================================

  static const white = Colors.white;

  static const black = Colors.black;

  static const transparent = Colors.transparent;
}
