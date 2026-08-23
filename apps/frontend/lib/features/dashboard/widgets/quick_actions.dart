import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return NexoraSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aksi cepat', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _ActionItem(icon: LucideIcons.arrowDownToLine, label: 'Pemasukan', color: AppColors.success, onTap: () => context.push('/add-income'))),
              Expanded(child: _ActionItem(icon: LucideIcons.arrowUpFromLine, label: 'Pengeluaran', color: AppColors.danger, onTap: () => context.push('/add-expense'))),
              Expanded(child: _ActionItem(icon: LucideIcons.walletMinimal, label: 'Wallet', color: AppColors.brandBright, onTap: () => context.go('/wallet'))),
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          scale: _pressed ? AppMotion.pressedScale : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: .10),
                  borderRadius: AppRadius.radiusMD,
                  border: Border.all(color: widget.color.withValues(alpha: .16)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}
