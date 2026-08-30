import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
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
    final remaining = totalLimit - totalSpent;
    final isOver = remaining < 0;
    final progress = totalLimit <= 0 ? 0.0 : (totalSpent / totalLimit).clamp(0.0, 1.0);
    final percentage = totalLimit <= 0 ? 0.0 : (totalSpent / totalLimit) * 100;
    final statusColor = isOver ? AppColors.danger : percentage >= 90 ? AppColors.danger : percentage >= 75 ? AppColors.warning : AppColors.success;

    return NCard(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Budget Summary', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(isOver ? 'Perlu perhatian' : 'Kontrol pengeluaranmu', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ])),
          TextButton(
            onPressed: () => context.push('/budget'),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('Lihat Semua  ›', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)),
          ),
        ]),
        if (items.isEmpty)
          const _EmptyBudget()
        else ...[
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(flex: 5, child: _HeroMetric(label: 'Budget bulan ini', value: rupiah(totalLimit))),
            const SizedBox(width: 12),
            Expanded(flex: 6, child: _HeroMetric(label: 'Terpakai', value: rupiah(totalSpent), valueColor: statusColor)),
            const SizedBox(width: 10),
            _ProgressRing(value: progress, percentage: percentage, isOver: isOver),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: .06), valueColor: AlwaysStoppedAnimation<Color>(statusColor)),
          ),
          const SizedBox(height: 9),
          Row(children: [
            Icon(isOver ? LucideIcons.triangleAlert : LucideIcons.checkCircle2, size: 14, color: statusColor),
            const SizedBox(width: 6),
            Expanded(child: Text(isOver ? 'Over budget ${rupiah(remaining.abs())}' : 'Sisa budget ${rupiah(remaining)}', style: AppTypography.caption.copyWith(color: statusColor, fontWeight: FontWeight.w800))),
            Text(isOver ? '${_budgetMultiple(totalSpent, totalLimit)}× budget' : '${percentage.toStringAsFixed(0)}% terpakai', style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ]),
          if (visibleItems.isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(height: 1, color: Colors.white.withValues(alpha: .055)),
            const SizedBox(height: 10),
            for (int i = 0; i < visibleItems.length; i++) ...[
              _BudgetRow(item: visibleItems[i]),
              if (i != visibleItems.length - 1) Divider(height: 17, color: Colors.white.withValues(alpha: .045)),
            ],
          ],
        ],
      ]),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 9)),
        const SizedBox(height: 3),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, maxLines: 1, softWrap: false, style: AppTypography.currency.copyWith(fontSize: 17, fontWeight: FontWeight.w900, color: valueColor ?? AppColors.textPrimary))),
      ]);
}

class _EmptyBudget extends StatelessWidget {
  const _EmptyBudget();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 4),
        child: SizedBox(width: double.infinity, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .10), shape: BoxShape.circle), child: const Icon(LucideIcons.walletCards, color: AppColors.primaryLight, size: 21)),
          const SizedBox(height: 8),
          Text('Belum Ada Budget', textAlign: TextAlign.center, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('Atur budget pertamamu untuk mulai\nmengontrol pengeluaran dengan Nexora.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.3)),
          const SizedBox(height: 9),
          FilledButton.icon(onPressed: () => context.push('/budget'), icon: const Icon(LucideIcons.plus, size: 15), label: const Text('Tambah Budget')),
        ])),
      );
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.percentage, required this.isOver});
  final double value;
  final double percentage;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    final color = isOver ? AppColors.danger : percentage >= 90 ? AppColors.danger : percentage >= 75 ? AppColors.warning : AppColors.primaryLight;
    return SizedBox(width: 50, height: 50, child: Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(value: value, strokeWidth: 4, backgroundColor: Colors.white.withValues(alpha: .06), valueColor: AlwaysStoppedAnimation<Color>(color)),
      Padding(padding: const EdgeInsets.all(4), child: FittedBox(fit: BoxFit.scaleDown, child: Text(isOver ? 'OVER' : '${percentage.toStringAsFixed(0)}%', style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: isOver ? 8 : 9)))),
    ]));
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.item});
  final BudgetItem item;

  @override
  Widget build(BuildContext context) {
    final percentage = item.limit <= 0 ? 0.0 : (item.spent / item.limit) * 100;
    final accent = item.isOverBudget ? AppColors.danger : item.progress >= .85 ? AppColors.warning : item.color;
    return Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: item.color.withValues(alpha: .08), borderRadius: BorderRadius.circular(10), border: Border.all(color: item.color.withValues(alpha: .10))), child: Icon(_icon(item.id), size: 16, color: item.color.withValues(alpha: .9))),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 11))),
          if (item.isOverBudget) Container(margin: const EdgeInsets.only(left: 5), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .10), borderRadius: BorderRadius.circular(999)), child: Text('OVER', style: AppTypography.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w900, fontSize: 7))),
        ]),
        const SizedBox(height: 5),
        ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: item.progress.clamp(0.0, 1.0), minHeight: 4, backgroundColor: Colors.white.withValues(alpha: .06), valueColor: AlwaysStoppedAnimation<Color>(accent))),
      ])),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text('${rupiah(item.spent)} / ${rupiah(item.limit)}', maxLines: 1, softWrap: false, style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 8))),
        const SizedBox(height: 3),
        Text(item.isOverBudget ? '${_budgetMultiple(item.spent, item.limit)}×' : '${percentage.toStringAsFixed(0)}%', style: AppTypography.caption.copyWith(color: accent, fontWeight: FontWeight.w900, fontSize: 9)),
      ]),
    ]);
  }
}

String _budgetMultiple(double spent, double limit) {
  if (limit <= 0) return '—';
  final multiple = spent / limit;
  if (multiple >= 100) return multiple.toStringAsFixed(0);
  if (multiple >= 10) return multiple.toStringAsFixed(1);
  return multiple.toStringAsFixed(2);
}

IconData _icon(String id) => switch (id) {
  'food' => LucideIcons.utensils,
  'transport' => LucideIcons.car,
  'shopping' => LucideIcons.shoppingBag,
  'entertainment' => LucideIcons.gamepad2,
  'health' => LucideIcons.heartPulse,
  'education' => LucideIcons.bookOpen,
  'bills' => LucideIcons.receiptText,
  _ => LucideIcons.circleDollarSign,
};
