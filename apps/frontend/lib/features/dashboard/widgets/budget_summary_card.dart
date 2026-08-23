import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora/nexora.dart';
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

    if (items.isEmpty) {
      return NexoraEmpty(
        icon: LucideIcons.wallet,
        title: 'Belum ada anggaran',
        reason: 'Buat anggaran per kategori agar pengeluaran tetap terkendali.',
        ctaLabel: 'Atur anggaran',
        onPressed: () => context.push('/budget'),
      );
    }

    return NexoraSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexoraSectionHeader(
            title: 'Anggaran',
            actionLabel: 'Lihat semua',
            onAction: () => context.push('/budget'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(rupiah(totalLimit), style: AppTypography.primaryAmount),
          const SizedBox(height: AppSpacing.sm),
          NexoraProgress(value: progress, color: isOver ? AppColors.danger : AppColors.brand),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text('Terpakai ${rupiah(totalSpent)}', style: AppTypography.caption)),
              Text(isOver ? 'Over ${rupiah(remaining.abs())}' : 'Sisa ${rupiah(remaining)}', style: AppTypography.caption.copyWith(color: isOver ? AppColors.danger : AppColors.success)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in visibleItems)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text(item.name, style: AppTypography.labelMedium)),
                  Text('${rupiah(item.spent)} / ${rupiah(item.limit)}', style: AppTypography.caption),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
