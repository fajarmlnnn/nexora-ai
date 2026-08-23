import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_typography.dart';
import 'nexora_amount.dart';
import 'nexora_chip.dart';

class NexoraTransactionTile extends StatefulWidget {
  const NexoraTransactionTile({
    super.key,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.onTap,
    this.pending = false,
    this.failed = false,
  });

  final String title;
  final num amount;
  final NexoraTransactionType type;
  final String category;
  final String date;
  final VoidCallback? onTap;
  final bool pending;
  final bool failed;

  @override
  State<NexoraTransactionTile> createState() => _NexoraTransactionTileState();
}

enum NexoraTransactionType { income, expense, transfer }

class _NexoraTransactionTileState extends State<NexoraTransactionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final direction = switch (widget.type) {
      NexoraTransactionType.income => NexoraAmountDirection.income,
      NexoraTransactionType.expense => NexoraAmountDirection.expense,
      NexoraTransactionType.transfer => NexoraAmountDirection.transfer,
    };
    final icon = switch (widget.type) {
      NexoraTransactionType.income => LucideIcons.arrowDownLeft,
      NexoraTransactionType.expense => LucideIcons.arrowUpRight,
      NexoraTransactionType.transfer => LucideIcons.arrowLeftRight,
    };
    final semanticColor = switch (widget.type) {
      NexoraTransactionType.income => AppColors.success,
      NexoraTransactionType.expense => AppColors.danger,
      NexoraTransactionType.transfer => AppColors.info,
    };
    final typeLabel = switch (widget.type) {
      NexoraTransactionType.income => 'Masuk',
      NexoraTransactionType.expense => 'Keluar',
      NexoraTransactionType.transfer => 'Transfer',
    };

    final content = AnimatedOpacity(
      opacity: widget.failed ? .55 : widget.pending ? .8 : 1,
      duration: AppMotion.fast,
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressedScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .06)))),
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: semanticColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)), child: Icon(icon, size: 20, color: semanticColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge),
                  const SizedBox(height: 4),
                  Text('${widget.category} • ${widget.date}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                ]),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                NexoraAmount(amount: widget.amount, role: NexoraAmountRole.list, direction: direction, showSign: true),
                const SizedBox(height: 4),
                NexoraChip(label: widget.failed ? 'Failed' : widget.pending ? 'Pending' : typeLabel, status: widget.failed ? NexoraChipStatus.danger : widget.pending ? NexoraChipStatus.warning : switch (widget.type) { NexoraTransactionType.income => NexoraChipStatus.success, NexoraTransactionType.expense => NexoraChipStatus.danger, NexoraTransactionType.transfer => NexoraChipStatus.info }),
              ]),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap == null) return Semantics(label: '${widget.title}, $typeLabel, ${widget.amount} rupiah, ${widget.date}', child: content);
    return Semantics(
      button: true,
      label: '${widget.title}, $typeLabel, ${widget.amount} rupiah, ${widget.date}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: content,
      ),
    );
  }
}
