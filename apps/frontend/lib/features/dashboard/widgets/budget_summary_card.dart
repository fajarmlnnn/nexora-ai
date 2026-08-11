import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
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
    final progress = totalLimit <= 0 ? 0.0 : (totalSpent / totalLimit).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return NCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Budget Summary',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
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
                  'Lihat Semua  ›',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (items.isEmpty)
            const _EmptyBudget()
          else ...[
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _Metric(label: 'Total Budget', value: rupiah(totalLimit))),
                const SizedBox(width: 8),
                Expanded(child: _Metric(label: 'Terpakai', value: rupiah(totalSpent))),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metric(
                    label: 'Sisa',
                    value: rupiah(remaining),
                    valueColor: remaining <= 0 ? AppColors.danger : AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                _ProgressRing(value: progress, percentage: percentage),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: .06),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            if (visibleItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (int i = 0; i < visibleItems.length; i++) ...[
                _BudgetRow(item: visibleItems[i]),
                if (i != visibleItems.length - 1)
                  Divider(height: 12, color: Colors.white.withValues(alpha: .055)),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyBudget extends StatelessWidget {
  const _EmptyBudget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.walletCards,
                color: AppColors.primaryLight,
                size: 21,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum Ada Budget',
              textAlign: TextAlign.center,
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              'Atur budget pertamamu untuk mulai\nmengontrol pengeluaran dengan Nexora.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 9),
            FilledButton.icon(
              onPressed: () => context.push('/budget'),
              icon: const Icon(LucideIcons.plus, size: 15),
              label: const Text('Tambah Budget'),
            ),
          ],
        ),
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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption.copyWith(fontSize: 8.5, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: AppTypography.currency.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      );
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
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 3.5,
            backgroundColor: Colors.white.withValues(alpha: .06),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text('$percentage%', style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 8)),
        ],
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: item.color.withValues(alpha: .10)),
          ),
          child: Icon(_icon(item.id), size: 15, color: item.color.withValues(alpha: .9)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 10.5)),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: .06),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('${rupiah(item.spent)} / ${rupiah(item.limit)}', maxLines: 1, softWrap: false, style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 8)),
            ),
            const SizedBox(height: 2),
            Text('$percentage%', style: AppTypography.caption.copyWith(color: accent, fontWeight: FontWeight.w800, fontSize: 8.5)),
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
