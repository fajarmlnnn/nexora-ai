import 'package:flutter/widgets.dart';

/// Nexora AI Design System
abstract final class AppSpacing {
  AppSpacing._();

  // Base
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  // Bottom Navigation
  static const double bottomNavHeight = 76;

  static double bottomNav(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + bottomNavHeight;
  }

  // Padding
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  static const EdgeInsets card = EdgeInsets.all(xl);

  static const EdgeInsets section = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  // Gap
  static const SizedBox gapXXS = SizedBox(height: xxs);
  static const SizedBox gapXS = SizedBox(height: xs);
  static const SizedBox gapSM = SizedBox(height: sm);
  static const SizedBox gapMD = SizedBox(height: md);
  static const SizedBox gapLG = SizedBox(height: lg);
  static const SizedBox gapXL = SizedBox(height: xl);
  static const SizedBox gapXXL = SizedBox(height: xxl);

  // Horizontal Gap
  static const SizedBox hGapXXS = SizedBox(width: xxs);
  static const SizedBox hGapXS = SizedBox(width: xs);
  static const SizedBox hGapSM = SizedBox(width: sm);
  static const SizedBox hGapMD = SizedBox(width: md);
  static const SizedBox hGapLG = SizedBox(width: lg);
  static const SizedBox hGapXL = SizedBox(width: xl);
}
