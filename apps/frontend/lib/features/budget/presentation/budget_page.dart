import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/widgets/budget_summary_card.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetItemsProvider);

    return PremiumScaffold(
      child: budgetsAsync.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: const [
            ShimmerSkeleton(width: 160, height: 32),
            SizedBox(height: 20),
            ShimmerSkeleton(height: 164),
            SizedBox(height: 20),
            ShimmerSkeleton(height: 300),
          ],
        ),
        error: (error, stackTrace) => Padding(
          padding: AppSpacing.screen,
          child: EmptyStateCard(
            icon: LucideIcons.triangleAlert,
            title: 'Budget belum tersedia',
            message: error.toString(),
            action: 'Coba Lagi',
          ),
        ),
        data: (items) => ListView(
          padding: AppSpacing.screen,
          children: [
            Text('Budget', style: AppTypography.heading1),
            Text('Ringkasan Budget Mei 2024', style: AppTypography.bodySmall),
            AppSpacing.gapLG,
            PremiumCard(
              child: Row(
                children: [
                  const Donut(
                    segments: [
                      DonutSegment(value: 39, color: AppColors.primary),
                      DonutSegment(value: 26, color: AppColors.info),
                      DonutSegment(value: 12, color: AppColors.warning),
                      DonutSegment(value: 23, color: AppColors.divider),
                    ],
                  ),
                  AppSpacing.hGapMD,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Budget', style: AppTypography.caption),
                        Text('Rp 5.000.000', style: AppTypography.heading3),
                        const SizedBox(height: 8),
                        Text('Terpakai Rp 3.900.000', style: AppTypography.bodySmall),
                        Text(
                          'Sisa Rp 1.100.000',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapLG,
            BudgetSummaryCard(items: items),
            AppSpacing.gapMD,
            const EmptyStateCard(
              icon: LucideIcons.walletCards,
              title: 'Budget baru siap dibuat',
              message: 'Tambahkan kategori untuk menjaga pengeluaran tetap sehat.',
              action: '+ Buat Budget',
            ),
          ],
        ),
      ),
    );
  }
}
