import 'package:flutter/animation.dart';

/// Nexora Motion Design Tokens
///
/// Semua animasi di aplikasi WAJIB menggunakan token ini.
/// Jangan gunakan Duration(milliseconds: xxx) secara langsung.
abstract final class AppMotion {
  AppMotion._();

  // ===========================
  // Duration
  // ===========================

  static const Duration instant = Duration(milliseconds: 100);

  static const Duration fast = Duration(milliseconds: 150);

  static const Duration normal = Duration(milliseconds: 250);

  static const Duration slow = Duration(milliseconds: 350);

  static const Duration page = Duration(milliseconds: 300);

  static const Duration chart = Duration(milliseconds: 600);

  static const Duration counter = Duration(milliseconds: 700);

  // ===========================
  // Curves
  // ===========================

  static const Curve standard = Curves.easeOutCubic;

  static const Curve emphasized = Curves.easeInOutCubic;

  static const Curve decelerate = Curves.decelerate;

  static const Curve accelerate = Curves.easeIn;

  static const Curve bounce = Curves.easeOutBack;

  // ===========================
  // Scale
  // ===========================

  static const double pressedScale = 0.97;

  static const double hoverScale = 1.02;

  // ===========================
  // Opacity
  // ===========================

  static const double disabledOpacity = 0.45;

  static const double hoverOpacity = 0.92;
}
