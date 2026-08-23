import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.brandPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.space800,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.brandPrimaryBright,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.space800,
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.info,
      onTertiary: AppColors.canvas,
      tertiaryContainer: AppColors.space800,
      onTertiaryContainer: Colors.white,
      surface: AppColors.canvas,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.space800,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderGlass,
      outlineVariant: AppColors.borderGlass,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Colors.white,
      onInverseSurface: AppColors.canvas,
      inversePrimary: AppColors.brandPrimaryDeep,
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: colorScheme,
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColors.borderGlass,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      cardColor: AppColors.space850,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.space800,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.borderGlass)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.borderGlass)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.danger, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD, borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.caption,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.heading1,
        headlineMedium: AppTypography.heading2,
        headlineSmall: AppTypography.heading3,
        titleLarge: AppTypography.heading2,
        titleMedium: AppTypography.heading3,
        titleSmall: AppTypography.heading4,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.caption,
      ),
    );
  }
}
