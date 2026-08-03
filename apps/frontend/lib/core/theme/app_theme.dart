import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Nexora AI Theme
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      fontFamily: AppTypography.fontFamily,

      scaffoldBackgroundColor: AppColors.background,

      colorScheme: colorScheme,

      splashFactory: InkRipple.splashFactory,

      dividerColor: AppColors.divider,

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),

      cardColor: AppColors.card,

      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        headlineLarge: AppTypography.heading1,
        headlineMedium: AppTypography.heading2,
        headlineSmall: AppTypography.heading3,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
      ),
    );
  }
}
