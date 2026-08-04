import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../models/transaction_model.dart';

class RecentTransactionCard extends StatelessWidget {
  const RecentTransactionCard({super.key, required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent Transactions', style: AppTypography.heading3),
            const Spacer(),
            Text('See All', style: AppTypography.bodySmall),
          ],
        ),
        AppSpacing.gapMD,
        for (int i = 0; i < transactions.length; i++) ...[
          _TransactionTile(transaction: transactions[i]),
          if (i != transactions.length - 1) AppSpacing.gapSM,
        ],
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionModel transaction;

  IconData get icon {
    switch (transaction.category) {
      case TransactionCategory.food:
        return LucideIcons.utensils;
      case TransactionCategory.shopping:
        return LucideIcons.shoppingBag;
      case TransactionCategory.salary:
        return LucideIcons.car;
      case TransactionCategory.transport:
        return LucideIcons.car;
      case TransactionCategory.investment:
        return LucideIcons.chartColumn;
      case TransactionCategory.health:
        return LucideIcons.heartPulse;
      case TransactionCategory.education:
        return LucideIcons.graduationCap;
      case TransactionCategory.bills:
        return LucideIcons.receipt;
      case TransactionCategory.entertainment:
        return LucideIcons.film;
      case TransactionCategory.other:
        return LucideIcons.circleDollarSign;
    }
  }

  Color get color =>
      transaction.isIncome ? AppColors.success : AppColors.danger;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.radiusMD,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        AppSpacing.hGapMD,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.title, style: AppTypography.labelLarge),
              Text(
                transaction.isIncome ? 'Pemasukan' : 'Pengeluaran',
                style: AppTypography.labelMedium.copyWith(color: color),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.isIncome ? '+' : '-'}${rupiah(transaction.amount)}',
              style: AppTypography.labelLarge.copyWith(color: color),
            ),
            Text(
              DateFormat('dd MMM yyyy').format(transaction.date),
              style: AppTypography.caption,
            ),
          ],
        ),
      ],
    );
  }
}
