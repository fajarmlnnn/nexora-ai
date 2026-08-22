import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
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
      primaryContainer: AppColors.brandPrimaryDeep,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.brandSecondary,
      onSecondary: const Color(0xFF04101A),
      secondaryContainer: AppColors.cardSecondary,
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.brandMagenta,
      onTertiary: const Color(0xFF170F48),
      tertiaryContainer: AppColors.heroIconBox,
      onTertiaryContainer: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.card,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderGlass,
      outlineVariant: AppColors.divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Colors.white,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.brandPrimaryBright,
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.radiusXL,
      borderSide: BorderSide(color: AppColors.borderGlass.withValues(alpha: .8)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.space950,
      colorScheme: colorScheme,
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColors.divider,
      visualDensity: VisualDensity.standard,
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
      cardColor: AppColors.card,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceGlassDark.withValues(alpha: .52),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: AppTypography.caption.copyWith(color: AppColors.brandPrimaryBright, fontWeight: FontWeight.w700),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder.copyWith(borderSide: BorderSide(color: AppColors.borderGlass.withValues(alpha: .32))),
        focusedBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.brandPrimaryBright, width: 1.4)),
        errorBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 1.2)),
        focusedErrorBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 1.4)),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.brandPrimary,
          disabledBackgroundColor: AppColors.brandPrimary.withValues(alpha: .30),
          disabledForegroundColor: Colors.white.withValues(alpha: .55),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPrimaryBright,
          textStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandPrimaryBright,
        circularTrackColor: AppColors.divider,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.space800,
        contentTextStyle: AppTypography.labelMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      ),
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
