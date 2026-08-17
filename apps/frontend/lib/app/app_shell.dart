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
      height: 92 + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 4, 14, bottomInset + 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xF21B1730),
                    Color(0xF0121424),
                    Color(0xEE10182A),
                  ],
                  stops: [0, .48, 1],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .14),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .48),
                    blurRadius: 30,
                    spreadRadius: -8,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .24),
                    blurRadius: 34,
                    spreadRadius: -13,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: const Color(0xFF5B7CFF).withValues(alpha: .10),
                    blurRadius: 28,
                    spreadRadius: -14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotWidth = constraints.maxWidth / 5;
                  final indicatorWidth = slotWidth - 14;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // One and only one active surface. The single animated
                      // indicator moves between slots, so no old bubble/glow
                      // can remain behind when switching tabs.
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 430),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment(-1 + (_activeSlot * .5), 0),
                        child: SizedBox(
                          width: indicatorWidth,
                          height: 58,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0x6B9A7BFF),
                                    Color(0x5B7049FF),
                                    Color(0x3A4669FF),
                                  ],
                                  stops: [0, .5, 1],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x667C4DFF),
                                    blurRadius: 25,
                                    spreadRadius: -8,
                                    offset: Offset(0, 7),
                                  ),
                                  BoxShadow(
                                    color: Color(0x3D6E8CFF),
                                    blurRadius: 20,
                                    spreadRadius: -7,
                                    offset: Offset(0, -3),
                                  ),
                                ],
                              ),
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
              height: 76,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1.07 : .98,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(
                        0,
                        selected ? -1.5 : 0,
                        0,
                      ),
                      child: Icon(
                        icon,
                        size: selected ? 25 : 22,
                        color: selected
                            ? Colors.white
                            : const Color(0xFFC5CBDA).withValues(alpha: .92),
                        shadows: selected
                            ? [
                                Shadow(
                                  color: AppColors.primaryLight.withValues(alpha: .55),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    style: AppTypography.caption.copyWith(
                      color: selected
                          ? Colors.white
                          : const Color(0xFFC5CBDA).withValues(alpha: .90),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 9.5,
                      height: 1.05,
                      letterSpacing: .05,
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.button,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .22),
                  width: 1,
                ),
                boxShadow: [
                  ...AppShadows.button,
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .42),
                    blurRadius: 28,
                    spreadRadius: -3,
                  ),
                  BoxShadow(
                    color: const Color(0xFF5B7CFF).withValues(alpha: .18),
                    blurRadius: 20,
                    spreadRadius: -5,
                    offset: const Offset(0, -4),
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
