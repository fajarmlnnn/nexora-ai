import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return NCard(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ActionItem(icon: LucideIcons.arrowDownToLine, label: 'Pemasukan', color: AppColors.success, onTap: () => context.push('/add-income'))),
              Expanded(child: _ActionItem(icon: LucideIcons.arrowUpFromLine, label: 'Pengeluaran', color: AppColors.danger, onTap: () => context.push('/add-expense'))),
              Expanded(child: _ActionItem(icon: LucideIcons.walletMinimal, label: 'Wallet', color: AppColors.primaryLight, onTap: () => context.go('/wallet'))),
              Expanded(child: _ActionItem(icon: LucideIcons.arrowLeftRight, label: 'Transfer', color: AppColors.info, onTap: () => context.push('/transfer'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatefulWidget {
  const _ActionItem({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<_ActionItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? .94 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: .075),
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withValues(alpha: .13)),
              ),
              child: Icon(widget.icon, color: widget.color.withValues(alpha: .88), size: 19),
            ),
            const SizedBox(height: 6),
            Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
