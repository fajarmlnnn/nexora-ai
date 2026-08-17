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

  int get _activeSlot => currentIndex < 2 ? currentIndex : currentIndex + 1;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 84 + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 4, 14, bottomInset + 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: .82),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .09),
                ),
                boxShadow: [
                  ...AppShadows.floating,
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .10),
                    blurRadius: 34,
                    spreadRadius: -10,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotWidth = constraints.maxWidth / 5;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // One shared active surface. It physically slides between
                      // destinations instead of creating a separate purple
                      // circle behind every icon.
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 460),
                        curve: Curves.easeInOutCubicEmphasized,
                        left: slotWidth * _activeSlot + 5,
                        top: 5,
                        width: slotWidth - 10,
                        height: 62,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: .23),
                                  AppColors.primary.withValues(alpha: .10),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(
                                  alpha: .18,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: .18),
                                  blurRadius: 22,
                                  spreadRadius: -7,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
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
                    ],
                  );
                },
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            splashColor: AppColors.primary.withValues(alpha: .10),
            highlightColor: Colors.white.withValues(alpha: .025),
            onTap: () => onTap(index),
            child: SizedBox(
              height: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutBack,
                    scale: selected ? 1.06 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(
                        0,
                        selected ? -1.5 : 0,
                        0,
                      ),
                      child: Icon(
                        icon,
                        size: selected ? 24 : 22,
                        color: selected
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 320),
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
