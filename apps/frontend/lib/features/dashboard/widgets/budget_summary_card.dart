import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/budget_item.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key, required this.items});

  final List<BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    final categories = [
      ...items,
      const BudgetItem(id: 'entertainment', name: 'Fun', spent: 270, limit: 1000, color: AppColors.danger),
      const BudgetItem(id: 'other', name: 'Other', spent: 150, limit: 1000, color: AppColors.textMuted),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Text('Budget Summary', style: AppTypography.heading3), const Spacer(), Text('See All', style: AppTypography.bodySmall)]),
        AppSpacing.gapMD,
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => AppSpacing.hGapMD,
            itemBuilder: (context, index) => _BudgetCircle(item: categories[index]),
          ),
        ),
      ],
    );
  }
}

class _BudgetCircle extends StatelessWidget {
  const _BudgetCircle({required this.item});

  final BudgetItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(value: item.progress, strokeWidth: 6, color: item.color, backgroundColor: AppColors.divider),
                Center(child: Container(width: 38, height: 38, decoration: BoxDecoration(color: item.color.withValues(alpha: .14), shape: BoxShape.circle), child: Icon(_icon(item.id), color: item.color, size: 18))),
              ],
            ),
          ),
          AppSpacing.gapXS,
          Text(item.name, style: AppTypography.caption.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${(item.progress * 100).round()}%', style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
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
  _ => LucideIcons.circleDollarSign,
};
