import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nexora 2.0 typography scale.
///
/// Plus Jakarta Sans is the only product UI typeface. Financial amounts use
/// tabular figures so values do not visually jump while data changes.
abstract final class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Plus Jakarta Sans';
  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  static const TextStyle displayLarge = TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.10, color: AppColors.textPrimary);
  static const TextStyle displaySmall = displayLarge;
  static const TextStyle heading1 = TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.15, color: AppColors.textPrimary);
  static const TextStyle heading2 = TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25, color: AppColors.textPrimary);
  static const TextStyle heading3 = TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.30, color: AppColors.textPrimary);
  static const TextStyle heading4 = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.35, color: AppColors.textPrimary);

  static const TextStyle bodyLarge = TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.50, color: AppColors.textPrimary);
  static const TextStyle bodyMedium = TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.50, color: AppColors.textSecondary);
  static const TextStyle bodySmall = TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.45, color: AppColors.textSecondary);
  static const TextStyle labelLarge = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.30, color: AppColors.textPrimary);
  static const TextStyle labelMedium = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.30, color: AppColors.textSecondary);
  static const TextStyle caption = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2, height: 1.30, color: AppColors.textMuted);
  static const TextStyle overline = TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, height: 1.20, color: AppColors.textMuted);

  static const TextStyle heroAmount = TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.10, color: AppColors.textPrimary, fontFeatures: tabularFigures);
  static const TextStyle primaryAmount = TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.20, color: AppColors.textPrimary, fontFeatures: tabularFigures);
  static const TextStyle secondaryAmount = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.30, color: AppColors.textPrimary, fontFeatures: tabularFigures);
  static const TextStyle listAmount = TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.30, color: AppColors.textPrimary, fontFeatures: tabularFigures);
  static const TextStyle percentage = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.30, fontFeatures: tabularFigures);
  static const TextStyle moneyLabel = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0, height: 1.30, color: AppColors.textMuted);
  static const TextStyle moneyMetadata = TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.30, color: AppColors.textMuted);

  static const TextStyle display = displayLarge;
  static const TextStyle balance = heroAmount;
  static const TextStyle currency = primaryAmount;
  static const TextStyle amountSmall = listAmount;
  static const TextStyle title = labelLarge;
  static const TextStyle label = labelLarge;
}
