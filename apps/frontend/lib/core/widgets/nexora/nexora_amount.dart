import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_typography.dart';

class NexoraAmount extends StatelessWidget {
  const NexoraAmount({
    super.key,
    required this.amount,
    this.role = NexoraAmountRole.list,
    this.direction = NexoraAmountDirection.neutral,
    this.label,
    this.metadata,
    this.showSign = false,
    this.animate = false,
    this.masked = false,
    this.semanticsLabel,
  });

  final num amount;
  final NexoraAmountRole role;
  final NexoraAmountDirection direction;
  final String? label;
  final String? metadata;
  final bool showSign;
  final bool animate;
  final bool masked;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final style = switch (role) {
      NexoraAmountRole.hero => AppTypography.heroAmount,
      NexoraAmountRole.primary => AppTypography.primaryAmount,
      NexoraAmountRole.secondary => AppTypography.secondaryAmount,
      NexoraAmountRole.list => AppTypography.listAmount,
    };
    final color = switch (direction) {
      NexoraAmountDirection.neutral => AppColors.textPrimary,
      NexoraAmountDirection.income => AppColors.success,
      NexoraAmountDirection.expense => AppColors.danger,
      NexoraAmountDirection.transfer => AppColors.info,
    };
    final formatted = masked ? 'Rp •••••••' : _formatRupiah(amount, showSign, direction);

    Widget value = Text(
      formatted,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(color: color),
    );

    if (animate && role == NexoraAmountRole.hero && !masked) {
      value = _CountUpAmount(amount: amount, style: style.copyWith(color: color), direction: direction, showSign: showSign);
    }

    final spoken = semanticsLabel ?? _spokenLabel(amount, direction);
    return Semantics(
      label: spoken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(label!, style: AppTypography.moneyLabel),
            const SizedBox(height: 4),
          ],
          value,
          if (metadata != null) ...[
            const SizedBox(height: 4),
            Text(metadata!, style: AppTypography.moneyMetadata),
          ],
        ],
      ),
    );
  }

  static String _formatRupiah(num value, bool sign, NexoraAmountDirection direction) {
    final digits = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value.abs());
    if (!sign) return digits;
    return switch (direction) {
      NexoraAmountDirection.income => '+$digits',
      NexoraAmountDirection.expense => '-$digits',
      NexoraAmountDirection.transfer => '↔$digits',
      NexoraAmountDirection.neutral => digits,
    };
  }

  static String _spokenLabel(num value, NexoraAmountDirection direction) {
    final number = NumberFormat.decimalPattern('id_ID').format(value.abs());
    final suffix = switch (direction) {
      NexoraAmountDirection.income => 'masuk',
      NexoraAmountDirection.expense => 'keluar',
      NexoraAmountDirection.transfer => 'transfer',
      NexoraAmountDirection.neutral => '',
    };
    return 'Rp $number rupiah${suffix.isEmpty ? '' : ' $suffix'}';
  }
}

enum NexoraAmountRole { hero, primary, secondary, list }
enum NexoraAmountDirection { neutral, income, expense, transfer }

class _CountUpAmount extends StatefulWidget {
  const _CountUpAmount({required this.amount, required this.style, required this.direction, required this.showSign});
  final num amount;
  final TextStyle style;
  final NexoraAmountDirection direction;
  final bool showSign;

  @override
  State<_CountUpAmount> createState() => _CountUpAmountState();
}

class _CountUpAmountState extends State<_CountUpAmount> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppMotion.counter)..forward();
  late final Animation<double> _animation = CurvedAnimation(parent: _controller, curve: AppMotion.standard);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Text(
        NexoraAmount._formatRupiah(widget.amount * _animation.value, widget.showSign, widget.direction),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      ),
    );
  }
}
