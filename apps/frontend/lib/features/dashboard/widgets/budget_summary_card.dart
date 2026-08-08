import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/layout/n_section_header.dart';
import '../../../core/widgets/premium_widgets.dart';

import '../models/budget_item.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key, required this.items});

  final List<BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    final budgets = items.take(3).toList();

    return NCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          NSectionHeader(
            title: "Budget Summary",
            actionLabel: "See All",
            onActionPressed: () {},
          ),

          AppSpacing.gapMD,

          for (final item in budgets)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _BudgetTile(item: item),
            ),
        ],
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({required this.item});

  final BudgetItem item;

  Color get progressColor {
    if (item.progress >= .85) return AppColors.danger;
    if (item.progress >= .60) return AppColors.warning;
    return AppColors.success;
  }

  String get status {
    if (item.progress >= .85) return "Critical";
    if (item.progress >= .60) return "Warning";
    return "Safe";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: progressColor.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_icon(item.id), color: progressColor, size: 20),
        ),

        AppSpacing.hGapMD,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: AppTypography.caption.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: item.progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      color: progressColor,
                      backgroundColor: Colors.white.withValues(alpha: .06),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${rupiah(item.spent)} / ${rupiah(item.limit)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: .70),
                      ),
                    ),
                  ),

                  Text(
                    "${(item.progress * 100).round()}%",
                    style: AppTypography.caption.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
