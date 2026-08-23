import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

class NexoraChip extends StatefulWidget {
  const NexoraChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.status,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final NexoraChipStatus? status;
  final Widget? icon;

  @override
  State<NexoraChip> createState() => _NexoraChipState();
}

enum NexoraChipStatus { success, warning, danger, info }

class _NexoraChipState extends State<NexoraChip> {
  bool _pressed = false;

  Color get _semanticColor => switch (widget.status) {
        NexoraChipStatus.success => AppColors.success,
        NexoraChipStatus.warning => AppColors.warning,
        NexoraChipStatus.danger => AppColors.danger,
        NexoraChipStatus.info => AppColors.info,
        null => AppColors.brandPrimary,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.status == null ? null : _semanticColor;
    final background = widget.selected
        ? AppColors.brandPrimary.withValues(alpha: .16)
        : statusColor?.withValues(alpha: .12) ?? AppColors.space800;
    final borderColor = widget.selected
        ? AppColors.brandPrimaryBright.withValues(alpha: .4)
        : statusColor?.withValues(alpha: .25) ?? AppColors.borderGlass;

    return Semantics(
      button: widget.onSelected != null,
      selected: widget.onSelected != null ? widget.selected : null,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onSelected == null ? null : () => widget.onSelected!(!widget.selected),
        onTapDown: widget.onSelected == null ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.onSelected == null ? null : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onSelected == null ? null : () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? AppMotion.pressedScale : 1,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.radiusPill,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 6)],
                Text(widget.label, style: AppTypography.caption.copyWith(color: statusColor ?? (widget.selected ? Colors.white : AppColors.textSecondary), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
