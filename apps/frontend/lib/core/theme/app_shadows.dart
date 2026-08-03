import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static final Shadow textShadow = Shadow(
    color: Colors.black.withValues(alpha: 0.15),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.18),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static final List<BoxShadow> glow = [
    BoxShadow(
      color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
      blurRadius: 40,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
