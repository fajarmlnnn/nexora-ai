import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_typography.dart';

class NexoraNav extends StatelessWidget {
  const NexoraNav({super.key, required this.currentIndex, required this.onTap, required this.onAdd});

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: 64 + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.canvasElevated.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: AppColors.borderGlass),
                boxShadow: AppShadows.floating,
              ),
              child: Row(
                children: [
                  _NavItem(index: 0, currentIndex: currentIndex, icon: LucideIcons.house, label: 'Beranda', onTap: onTap),
                  _NavItem(index: 1, currentIndex: currentIndex, icon: LucideIcons.arrowLeftRight, label: 'Transaksi', onTap: onTap),
                  Expanded(child: Center(child: _AddButton(onTap: onAdd))),
                  _NavItem(index: 2, currentIndex: currentIndex, icon: LucideIcons.walletMinimal, label: 'Wallet', onTap: onTap),
                  _NavItem(index: 3, currentIndex: currentIndex, icon: LucideIcons.target, label: 'Goals', onTap: onTap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.index, required this.currentIndex, required this.icon, required this.label, required this.onTap});
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.index == widget.currentIndex;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onTap(widget.index),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? AppMotion.pressedScale : 1,
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 24, color: selected ? AppColors.textPrimary : AppColors.textMuted),
                  const SizedBox(height: 3),
                  Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: selected ? AppColors.textPrimary : AppColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  AnimatedContainer(duration: AppMotion.normal, curve: AppMotion.standard, width: selected ? 20 : 0, height: 2, decoration: BoxDecoration(color: selected ? Colors.white.withValues(alpha: .08) : Colors.transparent, borderRadius: AppRadius.radiusPill)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tambah transaksi',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? AppMotion.pressedScale : 1,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brandPrimaryBright, AppColors.brandPrimary, AppColors.brandPrimaryDeep]),
              border: Border.all(color: Colors.white.withValues(alpha: .24)),
              boxShadow: [
                ...AppShadows.button,
                BoxShadow(color: AppColors.brandPrimary.withValues(alpha: .20), blurRadius: 24, spreadRadius: 1),
              ],
            ),
            child: const Icon(LucideIcons.plus, size: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class NexoraCreateSheet extends StatelessWidget {
  const NexoraCreateSheet({
    super.key,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onAddWallet,
    required this.onAddGoal,
    required this.onAskAi,
  });

  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onAddWallet;
  final VoidCallback onAddGoal;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.paddingOf(context).bottom + 16),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(color: AppColors.canvasElevated, borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.borderGlass), boxShadow: AppShadows.modal),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: AppRadius.radiusPill))),
          const SizedBox(height: 20),
          Align(alignment: Alignment.centerLeft, child: Text('Tambah', style: AppTypography.heading2)),
          const SizedBox(height: 12),
          _Action(icon: LucideIcons.arrowDownLeft, title: 'Tambah Pemasukan', onTap: onAddIncome),
          _Action(icon: LucideIcons.arrowUpRight, title: 'Tambah Pengeluaran', onTap: onAddExpense),
          _Action(icon: LucideIcons.walletMinimal, title: 'Tambah Wallet', onTap: onAddWallet),
          _Action(icon: LucideIcons.target, title: 'Tambah Goal', onTap: onAddGoal),
          _Action(icon: LucideIcons.sparkles, title: 'Tanya Nexora AI', onTap: onAskAi),
        ]),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, label: title, child: InkWell(borderRadius: AppRadius.radiusLG, onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.brandPrimary.withValues(alpha: .12), borderRadius: AppRadius.radiusMD), child: Icon(icon, size: 20, color: AppColors.brandPrimaryBright)), const SizedBox(width: 12), Expanded(child: Text(title, style: AppTypography.labelLarge)), const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textMuted)]))));
  }
}
