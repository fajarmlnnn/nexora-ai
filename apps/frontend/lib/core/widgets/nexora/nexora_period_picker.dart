import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'nexora_icon_button.dart';
import 'nexora_surface.dart';

class NexoraPeriodPicker extends StatelessWidget {
  const NexoraPeriodPicker({
    super.key,
    required this.month,
    required this.onChanged,
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  DateTime get _normalized => DateTime(month.year, month.month);

  void _shift(int delta) {
    onChanged(DateTime(_normalized.year, _normalized.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy', 'id_ID').format(_normalized);
    return NexoraSurface(
      compact: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          NexoraIconButton(
            icon: LucideIcons.chevronLeft,
            tooltip: 'Bulan sebelumnya',
            onPressed: () => _shift(-1),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelLarge,
            ),
          ),
          NexoraIconButton(
            icon: LucideIcons.chevronRight,
            tooltip: 'Bulan berikutnya',
            onPressed: () => _shift(1),
          ),
        ],
      ),
    );
  }
}

class NexoraProgress extends StatelessWidget {
  const NexoraProgress({
    super.key,
    required this.value,
    this.color = AppColors.brand,
    this.trackColor,
    this.height = 8,
  });

  final double value;
  final Color color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: 'Progres ${(clamped * 100).round()} persen',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: trackColor ?? AppColors.space800,
          borderRadius: AppRadius.radiusPill,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: clamped,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: AppRadius.radiusPill),
          ),
        ),
      ),
    );
  }
}

class NexoraBanner extends StatelessWidget {
  const NexoraBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = NexoraBannerTone.info,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final NexoraBannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      NexoraBannerTone.info => AppColors.info,
      NexoraBannerTone.success => AppColors.success,
      NexoraBannerTone.warning => AppColors.warning,
      NexoraBannerTone.danger => AppColors.danger,
    };
    return NexoraSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Text(title!, style: AppTypography.labelLarge),
                Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(actionLabel!, style: AppTypography.labelMedium.copyWith(color: color)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum NexoraBannerTone { info, success, warning, danger }
