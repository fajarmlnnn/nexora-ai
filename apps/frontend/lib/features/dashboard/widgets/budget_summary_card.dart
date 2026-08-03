import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/budget_item.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key, required this.items});

  final List<BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Summary', style: AppTypography.heading3),

          AppSpacing.gapLG,

          for (int i = 0; i < items.length; i++) ...[
            _BudgetItemTile(item: items[i], currency: currency),
            if (i != items.length - 1) AppSpacing.gapMD,
          ],
        ],
      ),
    );
  }
}

class _BudgetItemTile extends StatelessWidget {
  const _BudgetItemTile({required this.item, required this.currency});

  final BudgetItem item;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(item.name, style: AppTypography.bodyLarge),

            const Spacer(),

            Text(
              '${currency.format(item.spent)} / ${currency.format(item.limit)}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),

        AppSpacing.gapXS,

        ClipRRect(
          borderRadius: AppRadius.radiusLG,
          child: LinearProgressIndicator(
            value: item.progress,
            minHeight: 8,
            color: item.color,
            backgroundColor: AppColors.divider,
          ),
        ),
      ],
    );
  }
}
