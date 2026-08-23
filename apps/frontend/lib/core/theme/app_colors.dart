import 'package:flutter/material.dart';

/// Nexora 2.0 color system.
///
/// Canonical tokens are listed first. One brand purple only.
abstract final class AppColors {
  AppColors._();

  // ============================================================
  // Nexora 2.0 — canonical
  // ============================================================
  static const canvas = Color(0xFF05040C);
  static const canvasElevated = Color(0xFF070612);
  static const space850 = Color(0xFF0B091A);
  static const space800 = Color(0xFF100D22);

  static const brandPrimary = Color(0xFF8B5CF6);
  static const brandPrimaryBright = Color(0xFFA78BFA);
  static const brandPrimaryDeep = Color(0xFF5B21B6);

  static const brand = brandPrimary;
  static const brandBright = brandPrimaryBright;
  static const brandDeep = brandPrimaryDeep;

  static const surface = space850;
  static const surfaceElevated = space800;
  static const glass = Color(0x14FFFFFF);
  static const glassStrong = Color(0x1FFFFFFF);
  static const surfaceGlass = glass;
  static const surfaceGlassStrong = glassStrong;

  static const border = Color(0x24FFFFFF);
  static const borderGlass = border;
  static const borderFocus = Color(0x668B5CF6);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB9B4C9);
  static const textMuted = Color(0xFF777187);
  static const textDisabled = Color(0xFF4D485A);

  static const success = Color(0xFF36D977);
  static const warning = Color(0xFFFFB648);
  static const danger = Color(0xFFFF5A5A);
  static const info = Color(0xFF38BDF8);
  static const ai = Color(0xFFC084FC);
  static const scrim = Color(0xCC05040C);

  static const brandSecondary = info;
  static const brandCyan = Color(0xFF67E8F9);
  static const brandMagenta = ai;
  static const chart1 = brandPrimary;
  static const chart2 = Color(0xFF4F8CFF);
  static const chart3 = success;
  static const chart4 = warning;
  static const chart5 = danger;
  static const chartPurple = chart1;
  static const chartBlue = chart2;
  static const chartGreen = chart3;
  static const chartOrange = chart4;
  static const chartRed = chart5;

  // One brand purple. Legacy names now resolve to the canonical brand.
  static const primary = brandPrimary;
  static const primaryLight = brandPrimaryBright;
  static const primaryDark = brandPrimaryDeep;
  static const aiAccent = ai;

  static const space950 = canvas;
  static const space900 = canvasElevated;
  static const nexoraBackgroundEdge = canvas;
  static const background = canvas;
  static const surfaceVariant = space800;
  static const card = space850;
  static const cardSecondary = space800;
  static const cardMuted = space800;
  static const heroCard = space850;
  static const heroSubCard = space800;
  static const heroIconBox = space800;
  static const aiPowered = canvasElevated;
  static const featureTile1 = canvasElevated;
  static const featureIcon1 = space800;
  static const featureTile2 = space850;
  static const featureIcon2 = brandDeep;
  static const featureTile3 = canvasElevated;
  static const featureIcon3 = space800;
  static const arrowButton = brandPrimary;
  static const chatBubble = space850;
  static const chatAvatar = brandPrimary;
  static const userBubble = space800;
  static const quickActionCard = canvasElevated;
  static const suggestion1 = brandPrimary;
  static const suggestion2 = space800;
  static const suggestion3 = space850;
  static const suggestion4 = brandBright;
  static const inputBar = canvasElevated;
  static const sendButton = brandPrimary;
  static const micCta = brandBright;
  static const headerButton = canvasElevated;
  static const goalsBackgroundEdge = canvas;
  static const goalsBackgroundCenter = canvasElevated;
  static const goalsSummaryCard = space850;
  static const goalsTrack = space800;
  static const goalsPurple = brandPrimary;
  static const goalsPurpleBright = brandBright;
  static const goalsTotalBadge = space800;
  static const goalsProgressTrack = space800;
  static const goalsCard = space850;
  static const goalsCardAlt = canvasElevated;
  static const goalsSavingIconOuter = brandPrimary;
  static const goalsSavingIconInner = space800;
  static const goalsWishlistIcon = space800;
  static const goalsWishlistAccent = Color(0xFFD65B9E);
  static const goalsWishlistText = Color(0xFFF472B6);
  static const goalsTravelIcon = space800;
  static const goalsPromo = canvasElevated;
  static const goalsPromoAvatar = canvas;
  static const goalsNav = canvasElevated;
  static const divider = border;
  static const overlay = scrim;
  static const elevated = space800;
  static const hover = space800;
  static const pressed = space800;

  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;
}
