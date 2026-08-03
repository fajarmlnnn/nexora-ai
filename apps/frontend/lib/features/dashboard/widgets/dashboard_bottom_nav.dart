import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXXL,
        boxShadow: AppShadows.card,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(Icons.home_rounded, true),
          _NavItem(Icons.swap_horiz_rounded, false),
          _CenterButton(),
          _NavItem(Icons.auto_awesome_rounded, false),
          _NavItem(Icons.person_rounded, false),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.icon, this.selected);

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 28,
      color: selected ? AppColors.primary : AppColors.textMuted,
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF9D7BFF), Color(0xFF7C4DFF)],
        ),
        boxShadow: AppShadows.glow,
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
    );
  }
}
