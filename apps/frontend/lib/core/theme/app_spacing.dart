import 'package:flutter/widgets.dart';

/// Nexora 2.0 spacing tokens. Base unit: 4pt.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  static const double screenGutter = 20;
  static const double sectionGap = 20;
  static const double bottomNavHeight = 64;

  static double bottomNav(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + bottomNavHeight;
  }

  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: screenGutter,
    vertical: lg,
  );

  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardLarge = EdgeInsets.all(lg);
  static const EdgeInsets section = EdgeInsets.symmetric(
    horizontal: screenGutter,
    vertical: lg,
  );

  static const SizedBox gapXXS = SizedBox(height: xxs);
  static const SizedBox gapXS = SizedBox(height: xs);
  static const SizedBox gapSM = SizedBox(height: sm);
  static const SizedBox gapMD = SizedBox(height: md);
  static const SizedBox gapLG = SizedBox(height: lg);
  static const SizedBox gapXL = SizedBox(height: xl);
  static const SizedBox gapXXL = SizedBox(height: xxl);

  static const SizedBox hGapXXS = SizedBox(width: xxs);
  static const SizedBox hGapXS = SizedBox(width: xs);
  static const SizedBox hGapSM = SizedBox(width: sm);
  static const SizedBox hGapMD = SizedBox(width: md);
  static const SizedBox hGapLG = SizedBox(width: lg);
  static const SizedBox hGapXL = SizedBox(width: xl);
}
