import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/models/transaction_model.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({required this.transactions, super.key});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final date = DateFormat('MMM d, y');

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            TransactionListTile(
              transaction: transactions[i],
              currency: currency,
              date: date,
            ),
            if (i != transactions.length - 1) const Divider(height: 28),
          ],
        ],
      ),
    );
  }
}

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    required this.transaction,
    required this.currency,
    required this.date,
    super.key,
  });

  final TransactionModel transaction;
  final NumberFormat currency;
  final DateFormat date;

  IconData get icon {
    return switch (transaction.category) {
      TransactionCategory.food => LucideIcons.utensils,
      TransactionCategory.shopping => LucideIcons.shoppingBag,
      TransactionCategory.salary => LucideIcons.wallet,
      TransactionCategory.transport => LucideIcons.car,
      TransactionCategory.investment => LucideIcons.chartColumn,
      TransactionCategory.health => LucideIcons.heartPulse,
      TransactionCategory.education => LucideIcons.graduationCap,
      TransactionCategory.bills => LucideIcons.receipt,
      TransactionCategory.entertainment => LucideIcons.film,
      TransactionCategory.other => LucideIcons.circleDollarSign,
    };
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
            color: color.withValues(alpha: .15),
            borderRadius: AppRadius.radiusLG,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        AppSpacing.hGapMD,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.title, style: AppTypography.bodyLarge),
              AppSpacing.gapXXS,
              Text(
                '${transaction.category.name} • ${date.format(transaction.date)}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        AppSpacing.hGapMD,
        Text(
          '${transaction.isIncome ? '+' : '-'}${currency.format(transaction.amount)}',
          style: AppTypography.labelLarge.copyWith(color: color),
        ),
      ],
    );
  }
}
