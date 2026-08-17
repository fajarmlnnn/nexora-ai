import 'dart:ui' as ui;

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
        // Let the page continue behind the floating navigation surface so the
        // bar reads as a layer above the app instead of a fixed footer.
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: _PremiumBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          onAdd: () => _showCreateSheet(context),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext parentContext) {
    showModalBottomSheet<void>(
      context: parentContext,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .55),
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CreateActionSheet(parentContext: parentContext),
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

    return SizedBox(
      height: 92 + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          4,
          14,
          bottomInset + 10,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: .72),
                ),
                boxShadow: [
                  ...AppShadows.floating,
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .12),
                    blurRadius: 28,
                    spreadRadius: -8,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                child: Row(
                  children: [
                    _NavItem(
                      label: 'Home',
                      icon: LucideIcons.house,
                      index: 0,
                      currentIndex: currentIndex,
                      onTap: onTap,
                    ),
                    _NavItem(
                      label: 'Transaksi',
                      icon: LucideIcons.arrowLeftRight,
                      index: 1,
                      currentIndex: currentIndex,
                      onTap: onTap,
                    ),
                    Expanded(
                      child: Center(child: _CenterButton(onTap: onAdd)),
                    ),
                    _NavItem(
                      label: 'Wallet',
                      icon: LucideIcons.walletMinimal,
                      index: 2,
                      currentIndex: currentIndex,
                      onTap: onTap,
                    ),
                    _NavItem(
                      label: 'Goals',
                      icon: LucideIcons.target,
                      index: 3,
                      currentIndex: currentIndex,
                      onTap: onTap,
                    ),
                  ],
                ),
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
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          splashColor: AppColors.primary.withValues(alpha: .12),
          highlightColor: Colors.transparent,
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: .16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: .18)
                    : Colors.transparent,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .14),
                        blurRadius: 18,
                        spreadRadius: -5,
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1.08 : 1,
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? AppColors.primaryLight
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: AppTypography.caption.copyWith(
                    color: selected
                        ? AppColors.primaryLight
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 9.5,
                    height: 1.05,
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
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tambah transaksi',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withValues(alpha: .16),
          highlightColor: Colors.white.withValues(alpha: .06),
          onTap: onTap,
          child: Hero(
            tag: 'nexora-add-action',
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.button,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .18),
                  width: 1,
                ),
                boxShadow: [
                  ...AppShadows.button,
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .28),
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.plus,
                color: Colors.white,
                size: 31,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateActionSheet extends StatelessWidget {
  const _CreateActionSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.radiusXXL,
          boxShadow: AppShadows.modal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetAction(
              icon: LucideIcons.receiptText,
              title: 'Add Income',
              subtitle: 'Catat gaji, bonus, atau pemasukan lain',
              onTap: () {
                Navigator.pop(context);
                parentContext.push('/add-income');
              },
            ),
            _SheetAction(
              icon: LucideIcons.receiptText,
              title: 'Add Expense',
              subtitle: 'Catat makan, transportasi, dan tagihan',
              onTap: () {
                Navigator.pop(context);
                parentContext.push('/add-expense');
              },
            ),
            _SheetAction(
              icon: LucideIcons.walletMinimal,
              title: 'Add Wallet',
              subtitle: 'Tambahkan rekening atau e-wallet baru',
              onTap: () {
                Navigator.pop(context);
                parentContext.go('/wallet');
              },
            ),
            _SheetAction(
              icon: LucideIcons.target,
              title: 'Add Goal',
              subtitle: 'Create a saving, debt, or wishlist goal',
              onTap: () {
                Navigator.pop(context);
                parentContext.go('/goals');
              },
            ),
            _SheetAction(
              icon: LucideIcons.sparkles,
              title: 'Ask Nexora AI',
              subtitle: 'Get personal money guidance',
              onTap: () {
                Navigator.pop(context);
                parentContext.push('/ai');
              },
            ),
          ],
        ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.radiusLG,
        splashColor: AppColors.primary.withValues(alpha: .15),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: AppRadius.radiusLG,
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.labelLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
