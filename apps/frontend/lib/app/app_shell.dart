import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_typography.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: _PremiumBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          onAdd: () => _showCreateSheet(context),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateActionSheet(),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  const _PremiumBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 78 + bottomInset,
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: .94),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: .55)),
        ),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          _NavItem(
            label: 'Dashboard',
            icon: LucideIcons.house,
            index: 0,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            label: 'Transactions',
            icon: LucideIcons.arrowLeftRight,
            index: 1,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          Expanded(
            child: Center(child: _CenterButton(onTap: onAdd)),
          ),
          _NavItem(
            label: 'Goals',
            icon: LucideIcons.badgeCheck,
            index: 2,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            label: 'Profile',
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
    required this.label,
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    return Expanded(
      child: InkWell(
        borderRadius: AppRadius.radiusLG,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: .12)
                : Colors.transparent,
            borderRadius: AppRadius.radiusLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 23,
                color: selected
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppTypography.caption.copyWith(
                  color: selected
                      ? AppColors.primaryLight
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'nexora-add-action',
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.button,
            boxShadow: AppShadows.button,
          ),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _CreateActionSheet extends StatelessWidget {
  const _CreateActionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXXL,
        boxShadow: AppShadows.modal,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: AppRadius.radiusLG,
            ),
          ),
          const SizedBox(height: 18),
          _SheetAction(
            icon: LucideIcons.receiptText,
            title: 'Add Transaction',
            subtitle: 'Record income or expense',
            onTap: () => Navigator.pop(context),
          ),
          _SheetAction(
            icon: LucideIcons.target,
            title: 'Add Goal',
            subtitle: 'Create a saving, debt, or wishlist goal',
            onTap: () => Navigator.pop(context),
          ),
          _SheetAction(
            icon: LucideIcons.sparkles,
            title: 'Ask Nexora AI',
            subtitle: 'Get personal money guidance',
            onTap: () {
              Navigator.pop(context);
              context.push('/ai');
            },
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: AppRadius.radiusLG,
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: AppTypography.labelLarge),
      subtitle: Text(subtitle, style: AppTypography.bodySmall),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: AppColors.textMuted,
      ),
    );
  }
}
