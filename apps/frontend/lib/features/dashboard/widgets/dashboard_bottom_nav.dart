import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({super.key, this.currentIndex = 0, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXXL,
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: LucideIcons.house,
            index: 0,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: LucideIcons.arrowLeftRight,
            index: 1,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          const _CenterButton(),
          _NavItem(
            icon: LucideIcons.sparkles,
            index: 2,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: LucideIcons.userRound,
            index: 3,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.index,
    required this.currentIndex,
    this.onTap,
  });

  final IconData icon;
  final int index;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  bool get selected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onTap?.call(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: .12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 24,
          color: selected ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.button,
        boxShadow: AppShadows.button,
      ),
      child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
    );
  }
}
