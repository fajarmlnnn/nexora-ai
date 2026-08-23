import 'package:flutter/widgets.dart';

/// Nexora 2.0 radius family: 8, 12, 16, 20, 24, 32, 999.
abstract final class AppRadius {
  AppRadius._();

  static const double r8 = 8;
  static const double r12 = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double pill = 999;

  static const double xs = r8;
  static const double sm = r12;

  static const BorderRadius radius8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius radius12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXXL = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius radiusXS = radius8;
  static const BorderRadius radiusSM = radius12;
}
