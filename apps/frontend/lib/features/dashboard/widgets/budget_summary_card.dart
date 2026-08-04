import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../models/budget_item.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key, required this.items});

  final List<BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    final categories = [
      ...items,
      const BudgetItem(
        id: 'entertainment',
        name: 'Hiburan',
        spent: 80000,
        limit: 300000,
        color: AppColors.danger,
      ),
      const BudgetItem(
        id: 'health',
        name: 'Kesehatan',
        spent: 50000,
        limit: 200000,
        color: AppColors.success,
      ),
    ];

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Budget Summary', action: 'Lihat Semua'),
          AppSpacing.gapMD,
          for (final item in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  PremiumIconBadge(icon: _icon(item.id), color: item.color, size: 40),
                  AppSpacing.hGapMD,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(item.name, style: AppTypography.labelMedium)),
                            Text(
                              '${(item.progress * 100).round()}%',
                              style: AppTypography.caption.copyWith(
                                color: item.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapXS,
                        AnimatedProgressBar(value: item.progress, color: item.color),
                        AppSpacing.gapXXS,
                        Text('${rupiah(item.spent)} / ${rupiah(item.limit)}', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

IconData _icon(String id) => switch (id) {
  'food' => LucideIcons.utensils,
  'transport' => LucideIcons.car,
  'shopping' => LucideIcons.shoppingBag,
  'entertainment' => LucideIcons.gamepad2,
  'health' => LucideIcons.heartPulse,
  _ => LucideIcons.circleDollarSign,
};
