import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({super.key, this.currentIndex = 0, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: ClipRRect(
          borderRadius: AppRadius.radiusXXL,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                // Match the Nexora AI Insight visual language.
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF080910),
                    Color(0xFF17102C),
                    Color(0xFF32155F),
                  ],
                ),
                borderRadius: AppRadius.radiusXXL,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: .15),
                ),
                boxShadow: [
                  ...AppShadows.floating,
                  // Slightly brighter than the AI Insight card so the nav
                  // remains visually distinct without becoming neon-heavy.
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .24),
                    blurRadius: 30,
                    spreadRadius: -6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: .12),
                    blurRadius: 22,
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.house,
                          label: 'Home',
                          index: 0,
                          currentIndex: currentIndex,
                          onTap: onTap,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.arrowLeftRight,
                          label: 'Wallet',
                          index: 1,
                          currentIndex: currentIndex,
                          onTap: onTap,
                        ),
                      ),
                      const SizedBox(width: 72),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.sparkles,
                          label: 'AI',
                          index: 2,
                          currentIndex: currentIndex,
                          onTap: onTap,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: LucideIcons.userRound,
                          label: 'Profile',
                          index: 3,
                          currentIndex: currentIndex,
                          onTap: onTap,
                        ),
                      ),
                    ],
                  ),
                  const Positioned(top: -22, child: _CenterButton()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  bool get selected => currentIndex == index;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => onTap?.call(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // Keep the selected state integrated with the glass instead of
          // creating a heavy purple bubble.
          color: selected
              ? AppColors.primary.withValues(alpha: .16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: selected
              ? Border.all(
                  color: AppColors.primaryLight.withValues(alpha: .14),
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: .16),
                    blurRadius: 18,
                    spreadRadius: -5,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 22,
                color: selected
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatefulWidget {
  const _CenterButton();

  @override
  State<_CenterButton> createState() => _CenterButtonState();
}

class _CenterButtonState extends State<_CenterButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: pressed ? .94 : 1,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFB794FF),
                Color(0xFF8B5CF6),
                Color(0xFF6D3DE0),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .16),
            ),
            boxShadow: [
              ...AppShadows.button,
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: .48),
                blurRadius: 30,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .30),
                blurRadius: 44,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
