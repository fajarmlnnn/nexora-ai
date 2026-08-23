import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import 'nexora_amount.dart';

class NexoraMetric extends StatelessWidget {
  const NexoraMetric({super.key, required this.label, required this.amount, this.icon, this.direction = NexoraAmountDirection.neutral});

  final String label;
  final num amount;
  final Widget? icon;
  final NexoraAmountDirection direction;

  @override
  Widget build(BuildContext context) {
    final iconColor = switch (direction) {
      NexoraAmountDirection.income => AppColors.success,
      NexoraAmountDirection.expense => AppColors.danger,
      NexoraAmountDirection.transfer => AppColors.info,
      NexoraAmountDirection.neutral => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .03),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            IconTheme(data: IconThemeData(size: 18, color: iconColor), child: icon!),
            const SizedBox(width: 8),
          ],
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTypography.moneyLabel), const SizedBox(height: 4), NexoraAmount(amount: amount, role: NexoraAmountRole.secondary, direction: direction, showSign: false)])),
        ],
      ),
    );
  }
}
