import 'package:flutter/widgets.dart';

/// Nexora 2.0 radius family.
abstract final class AppRadius {
  AppRadius._();

  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;

  /// Reserved for the bottom navigation capsule only.
  static const double xxl = 32;

  // Legacy aliases retained while screens migrate.
  static const double xs = md;
  static const double sm = md;

  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXXL = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius radiusXS = radiusMD;
  static const BorderRadius radiusSM = radiusMD;
}
