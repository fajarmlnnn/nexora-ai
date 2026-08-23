import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'nexora_sheet.dart';
import 'nexora_surface.dart';

class NexoraSelectOption<T> {
  const NexoraSelectOption({required this.value, required this.label, this.subtitle});
  final T value;
  final String label;
  final String? subtitle;
}

class NexoraSelect<T> extends StatelessWidget {
  const NexoraSelect({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.options,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final String valueLabel;
  final List<NexoraSelectOption<T>> options;
  final ValueChanged<T> onSelected;
  final bool enabled;

  Future<void> _open(BuildContext context) async {
    final selected = await NexoraSheet.show<T>(
      context: context,
      title: label,
      child: Column(
        children: [
          for (final option in options)
            NexoraSurface(
              compact: true,
              onTap: () => Navigator.pop(context, option.value),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.label, style: AppTypography.labelLarge),
                        if (option.subtitle != null)
                          Text(option.subtitle!, style: AppTypography.caption),
                      ],
                    ),
                  ),
                  if (option.label == valueLabel)
                    const Icon(LucideIcons.check, color: AppColors.brandBright, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return NexoraSurface(
      enabled: enabled,
      onTap: enabled ? () => _open(context) : null,
      semanticLabel: '$label, $valueLabel',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xxs),
                Text(valueLabel, style: AppTypography.labelLarge),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronDown, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
