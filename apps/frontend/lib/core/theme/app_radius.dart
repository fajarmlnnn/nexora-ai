import 'package:flutter/widgets.dart';

/// Nexora AI Design System
abstract final class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const BorderRadius radiusXS = BorderRadius.all(Radius.circular(xs));

  static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(sm));

  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(md));

  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(lg));

  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));

  static const BorderRadius radiusXXL = BorderRadius.all(Radius.circular(xxl));

  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(999));
}
