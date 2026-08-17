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
        padding: EdgeInsets.fromLTRB(18, 2, 18, bottomInset + 7),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xF0342B50),
                    Color(0xF025223F),
                    Color(0xF01D293E),
                  ],
                  stops: [0, .46, 1],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .20),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .48),
                    blurRadius: 28,
                    spreadRadius: -9,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: const Color(0xFFB579FF).withValues(alpha: .28),
                    blurRadius: 34,
                    spreadRadius: -13,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: const Color(0xFF6EA8FF).withValues(alpha: .18),
                    blurRadius: 30,
                    spreadRadius: -13,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotWidth = constraints.maxWidth / 5;
                  final indicatorWidth = slotWidth - 12;
                  final indicatorLeft = slotWidth * _activeSlot + 6;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 20,
                        right: 20,
                        top: 1,
                        height: 1.5,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: .24),
                                  const Color(0xFFBDA0FF).withValues(alpha: .22),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 430),
                        curve: Curves.easeOutCubic,
                        left: indicatorLeft,
                        top: 8,
                        width: indicatorWidth,
                        height: 50,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(23),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0x9EAB8AFF),
                                  Color(0x7A7656E9),
                                  Color(0x5C5E79D9),
                                ],
                                stops: [0, .50, 1],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .22),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x669B6CFF),
                                  blurRadius: 22,
                                  spreadRadius: -7,
                                  offset: Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Color(0x405B8CFF),
                                  blurRadius: 20,
                                  spreadRadius: -7,
                                  offset: Offset(0, -3),
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
            borderRadius: BorderRadius.circular(24),
            splashColor: const Color(0xFFB58AFF).withValues(alpha: .12),
            highlightColor: Colors.white.withValues(alpha: .035),
            onTap: () => onTap(index),
            child: SizedBox(
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1.05 : 1,
                    child: Icon(
                      icon,
                      size: selected ? 24 : 22,
                      color: selected
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFE1DEEB),
                      shadows: selected
                          ? const [
                              Shadow(
                                color: Color(0x889B6CFF),
                                blurRadius: 11,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    style: AppTypography.caption.copyWith(
                      color: selected
                          ? Colors.white
                          : const Color(0xFFD9D6E5),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 9.5,
                      height: 1.05,
                      letterSpacing: .02,
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

class _CenterButton extends StatefulWidget {
  const _CenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CenterButton> createState() => _CenterButtonState();
}

class _CenterButtonState extends State<_CenterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    lowerBound: .92,
    upperBound: 1,
    value: 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.reverse();
    await _controller.forward();
    if (mounted) widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tambah transaksi',
      child: ScaleTransition(
        scale: _controller,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC99BFF),
                  Color(0xFF9D6BFF),
                  Color(0xFF7042E8),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: .26),
                width: 1,
              ),
              boxShadow: [
                ...AppShadows.button,
                BoxShadow(
                  color: const Color(0xFFA46BFF).withValues(alpha: .66),
                  blurRadius: 23,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFF5B8CFF).withValues(alpha: .24),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.plus,
              color: Colors.white,
              size: 30,
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
