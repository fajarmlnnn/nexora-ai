import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
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
    final remaining = (totalLimit - totalSpent).clamp(0.0, double.infinity);
    final progress = totalLimit <= 0
        ? 0.0
        : (totalSpent / totalLimit).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return NCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Budget Summary',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/budget'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See All  ›',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _Metric(label: 'Total Budget', value: rupiah(totalLimit))),
              const SizedBox(width: 10),
              Expanded(child: _Metric(label: 'Terpakai', value: rupiah(totalSpent))),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Sisa',
                  value: rupiah(remaining),
                  valueColor: remaining <= 0 ? AppColors.danger : AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              _ProgressRing(value: progress, percentage: percentage),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: .06),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (visibleItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < visibleItems.length; i++) ...[
                  Expanded(child: _BudgetColumn(item: visibleItems[i])),
                  if (i != visibleItems.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.currency.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.percentage});

  final double value;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 90
        ? AppColors.danger
        : percentage >= 75
            ? AppColors.warning
            : AppColors.primaryLight;

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 4,
            backgroundColor: Colors.white.withValues(alpha: .06),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$percentage%',
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetColumn extends StatelessWidget {
  const _BudgetColumn({required this.item});

  final BudgetItem item;

  @override
  Widget build(BuildContext context) {
    final percentage = (item.progress * 100).round();
    final accent = item.isOverBudget
        ? AppColors.danger
        : item.progress >= .85
            ? AppColors.warning
            : item.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(9),
                boxShadow: AppShadows.soft,
              ),
              child: Icon(_icon(item.id), size: 15, color: item.color),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${rupiah(item.spent)} / ${rupiah(item.limit)}',
              maxLines: 1,
              softWrap: false,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 8.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
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
            const SizedBox(width: 5),
            Text(
              '$percentage%',
              style: AppTypography.caption.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ],
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
