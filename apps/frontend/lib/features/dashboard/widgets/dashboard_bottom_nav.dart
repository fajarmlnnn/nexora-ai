import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(Icons.home_rounded, true),
          _NavItem(Icons.swap_horiz_rounded, false),
          _NavItem(Icons.pie_chart_rounded, false),
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
      color: selected ? AppColors.primary : AppColors.textMuted,
      size: 28,
    );
  }
}
