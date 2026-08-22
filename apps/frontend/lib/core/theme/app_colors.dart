import 'package:flutter/material.dart';

/// Nexora 2.0 color system.
///
/// Legacy component tokens are intentionally kept below so the redesign can
/// land incrementally without breaking existing feature surfaces.
abstract final class AppColors {
  AppColors._();

  // ============================================================
  // Nexora 2.0 Brand
  // ============================================================
  static const brandPrimary = Color(0xFF8B5CF6);
  static const brandPrimaryBright = Color(0xFFA78BFA);
  static const brandPrimaryDeep = Color(0xFF5B21B6);
  static const brandSecondary = Color(0xFF38BDF8);
  static const brandCyan = Color(0xFF67E8F9);
  static const brandMagenta = Color(0xFFC084FC);

  static const space950 = Color(0xFF03020B);
  static const space900 = Color(0xFF070612);
  static const space850 = Color(0xFF0B091A);
  static const space800 = Color(0xFF100D22);
  static const surfaceGlass = Color(0x14FFFFFF);
  static const surfaceGlassStrong = Color(0x1FFFFFFF);
  static const surfaceGlassDark = Color(0x66080613);
  static const borderGlass = Color(0x24FFFFFF);
  static const borderFocus = Color(0x668B5CF6);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB9B4C9);
  static const textMuted = Color(0xFF777187);
  static const textDisabled = Color(0xFF4D485A);

  static const success = Color(0xFF36D977);
  static const successLight = Color(0xFF56E08A);
  static const warning = Color(0xFFFFB648);
  static const warningLight = Color(0xFFFFC96B);
  static const danger = Color(0xFFFF5A5A);
  static const dangerLight = Color(0xFFFF7B7B);
  static const info = Color(0xFF38BDF8);

  static const chartPurple = Color(0xFF8B5CF6);
  static const chartBlue = Color(0xFF4F8CFF);
  static const chartGreen = Color(0xFF36D977);
  static const chartOrange = Color(0xFFFFB648);
  static const chartRed = Color(0xFFFF5A5A);

  // ============================================================
  // Legacy / feature tokens
  // ============================================================
  static const primary = Color(0xFF4D25B1);
  static const primaryLight = Color(0xFFAD90F5);
  static const primaryDark = Color(0xFF351D83);
  static const aiAccent = Color(0xFF8E5FF6);

  static const nexoraBackgroundEdge = Color(0xFF00010A);
  static const background = Color(0xFF0A0A1F);
  static const surface = Color(0xFF0D0B20);
  static const surfaceVariant = Color(0xFF130B38);
  static const card = Color(0xFF0D0C19);
  static const cardSecondary = Color(0xFF110947);
  static const cardMuted = Color(0xFF19142E);

  static const heroCard = Color(0xFF170F48);
  static const heroSubCard = Color(0xFF211B3E);
  static const heroIconBox = Color(0xFF200B58);
  static const aiPowered = Color(0xFF090630);

  static const featureTile1 = Color(0xFF050715);
  static const featureIcon1 = Color(0xFF170D3D);
  static const featureTile2 = Color(0xFF130B38);
  static const featureIcon2 = Color(0xFF351D83);
  static const featureTile3 = Color(0xFF040615);
  static const featureIcon3 = Color(0xFF19142E);
  static const arrowButton = Color(0xFF4D25B1);

  static const chatBubble = Color(0xFF0D0C19);
  static const chatAvatar = Color(0xFF6632D9);
  static const userBubble = Color(0xFF111022);
  static const quickActionCard = Color(0xFF0A091D);
  static const suggestion1 = Color(0xFF734ECA);
  static const suggestion2 = Color(0xFF110947);
  static const suggestion3 = Color(0xFF0D0B31);
  static const suggestion4 = Color(0xFF8E5FF6);
  static const inputBar = Color(0xFF0A091D);
  static const sendButton = Color(0xFF4D25B1);
  static const micCta = Color(0xFFAD90F5);
  static const headerButton = Color(0xFF080A17);

  static const goalsBackgroundEdge = Color(0xFF000000);
  static const goalsBackgroundCenter = Color(0xFF0A0A12);
  static const goalsSummaryCard = Color(0xFF120F22);
  static const goalsTrack = Color(0xFF1A1830);
  static const goalsPurple = Color(0xFF6A3BD7);
  static const goalsPurpleBright = Color(0xFF9567FD);
  static const goalsTotalBadge = Color(0xFF1B1435);
  static const goalsProgressTrack = Color(0xFF1D1B30);
  static const goalsCard = Color(0xFF12121E);
  static const goalsCardAlt = Color(0xFF10101A);
  static const goalsSavingIconOuter = Color(0xFF6B54A2);
  static const goalsSavingIconInner = Color(0xFF261D48);
  static const goalsWishlistIcon = Color(0xFF2E1E3B);
  static const goalsWishlistAccent = Color(0xFFD65B9E);
  static const goalsWishlistText = Color(0xFFF472B6);
  static const goalsTravelIcon = Color(0xFF1F1F37);
  static const goalsPromo = Color(0xFF0C0C18);
  static const goalsPromoAvatar = Color(0xFF07040B);
  static const goalsNav = Color(0xFF0D111C);

  static const border = Color(0xFF292448);
  static const divider = Color(0xFF23213A);
  static const overlay = Color(0x88000000);
  static const glass = Color(0x14FFFFFF);
  static const elevated = Color(0xFF20203A);
  static const hover = Color(0xFF252044);
  static const pressed = Color(0xFF2B2450);

  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;
}
