import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

class NexoraListTile extends StatefulWidget {
  const NexoraListTile({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap, this.selected = false, this.standalone = false, this.semanticLabel});

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool standalone;
  final String? semanticLabel;

  @override
  State<NexoraListTile> createState() => _NexoraListTileState();
}

class _NexoraListTileState extends State<NexoraListTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tile = AnimatedScale(
      scale: _pressed ? AppMotion.pressedScale : 1,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: widget.standalone
            ? BoxDecoration(color: AppColors.space850, borderRadius: AppRadius.radiusLG, border: Border.all(color: AppColors.borderGlass))
            : BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .06)))),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              SizedBox(width: 40, height: 40, child: widget.leading),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge),
                  if (widget.subtitle != null) ...[const SizedBox(height: 4), Text(widget.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption)],
                ],
              ),
            ),
            if (widget.trailing != null) ...[const SizedBox(width: 12), widget.trailing!],
          ],
        ),
      ),
    );

    if (widget.onTap == null) return Semantics(label: widget.semanticLabel ?? widget.title, selected: widget.selected, child: tile);
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.title,
      selected: widget.selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: tile,
      ),
    );
  }
}
