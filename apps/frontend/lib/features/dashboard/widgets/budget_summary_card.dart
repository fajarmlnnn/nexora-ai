import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
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
    final visibleItems = items.take(3).toList();
    final totalLimit = items.fold<double>(0, (sum, item) => sum + item.limit);
    final totalSpent = items.fold<double>(0, (sum, item) => sum + item.spent);
    final overallProgress = totalLimit <= 0
        ? 0.0
        : (totalSpent / totalLimit).clamp(0.0, 1.0);
    final percentage = (overallProgress * 100).round();

    return NCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NSectionHeader(
            title: 'Budget Summary',
            actionLabel: 'See All',
            onActionPressed: () => context.push('/budget'),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Text(
                  rupiah(totalLimit),
                  style: AppTypography.currency.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ProgressBadge(percentage: percentage),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${rupiah(totalSpent)} terpakai dari ${rupiah(totalLimit)}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: .06),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (visibleItems.isNotEmpty) ...[
            const SizedBox(height: 11),
            Divider(height: 1, color: Colors.white.withValues(alpha: .06)),
            const SizedBox(height: 8),
            for (int i = 0; i < visibleItems.length; i++) ...[
              _BudgetRow(item: visibleItems[i]),
              if (i != visibleItems.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 90
        ? AppColors.danger
        : percentage >= 75
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        '$percentage%',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.item});

  final BudgetItem item;

  @override
  Widget build(BuildContext context) {
    final percentage = (item.progress * 100).round();
    final accent = item.isOverBudget
        ? AppColors.danger
        : item.progress >= .85
            ? AppColors.warning
            : item.color;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(9),
            boxShadow: AppShadows.soft,
          ),
          child: Icon(_icon(item.id), size: 15, color: item.color),
        ),
        AppSpacing.hGapSM,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: AppTypography.caption.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: .06),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${rupiah(item.spent)} / ${rupiah(item.limit)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 8.5,
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

IconData _icon(String id) {
  return switch (id) {
    'food' => LucideIcons.utensils,
    'transport' => LucideIcons.car,
    'shopping' => LucideIcons.shoppingBag,
    'entertainment' => LucideIcons.gamepad2,
    'health' => LucideIcons.heartPulse,
    'education' => LucideIcons.bookOpen,
    'bills' => LucideIcons.receiptText,
    _ => LucideIcons.circleDollarSign,
  };
}
