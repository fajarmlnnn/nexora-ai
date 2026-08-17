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
      height: 94 + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 4, 14, bottomInset + 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xE92B2445),
                    Color(0xE51D1A33),
                    Color(0xE3161C2D),
                  ],
                  stops: [0, .48, 1],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .52),
                    blurRadius: 32,
                    spreadRadius: -8,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: const Color(0xFF9B6CFF).withValues(alpha: .22),
                    blurRadius: 38,
                    spreadRadius: -12,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: const Color(0xFF5B8CFF).withValues(alpha: .11),
                    blurRadius: 34,
                    spreadRadius: -14,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotWidth = constraints.maxWidth / 5;
                  final indicatorWidth = slotWidth - 10;
                  final indicatorLeft = slotWidth * _activeSlot + 5;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Soft glass highlight across the top edge.
                      Positioned(
                        left: 22,
                        right: 22,
                        top: 1,
                        height: 1.5,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: .14),
                                  const Color(0xFFB58AFF).withValues(alpha: .10),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ONE active glass surface. It physically moves between
                      // slots, so there is never an old bubble left behind.
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 430),
                        curve: Curves.easeOutCubic,
                        left: indicatorLeft,
                        top: 7,
                        width: indicatorWidth,
                        height: 60,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0x759E7CFF),
                                  Color(0x4E7551E9),
                                  Color(0x315C78E8),
                                ],
                                stops: [0, .52, 1],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .17),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x4D9B6CFF),
                                  blurRadius: 24,
                                  spreadRadius: -8,
                                  offset: Offset(0, 7),
                                ),
                                BoxShadow(
                                  color: Color(0x265B8CFF),
                                  blurRadius: 22,
                                  spreadRadius: -8,
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
            borderRadius: BorderRadius.circular(28),
            splashColor: const Color(0xFFB58AFF).withValues(alpha: .10),
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
                    scale: selected ? 1.08 : 1,
                    child: Icon(
                      icon,
                      size: selected ? 25 : 23,
                      color: selected
                          ? const Color(0xFFF2EBFF)
                          : const Color(0xFFD0CDDC),
                      shadows: selected
                          ? const [
                              Shadow(
                                color: Color(0x779B6CFF),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    style: AppTypography.caption.copyWith(
                      color: selected
                          ? const Color(0xFFF1E9FF)
                          : const Color(0xFFC3C0CE),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10,
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC08BFF),
                  Color(0xFF9561FF),
                  Color(0xFF6739DE),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: .22),
                width: 1,
              ),
              boxShadow: [
                ...AppShadows.button,
                BoxShadow(
                  color: const Color(0xFFA46BFF).withValues(alpha: .62),
                  blurRadius: 25,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFF5B7CFF).withValues(alpha: .18),
                  blurRadius: 30,
                  spreadRadius: -4,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.plus,
              color: Colors.white,
              size: 32,
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
