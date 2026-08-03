import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/transaction_model.dart';

class RecentTransactionCard extends StatelessWidget {
  const RecentTransactionCard({super.key, required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXL,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Transactions', style: AppTypography.heading3),

          AppSpacing.gapLG,

          for (int i = 0; i < transactions.length; i++) ...[
            _TransactionTile(transaction: transactions[i], currency: currency),
            if (i != transactions.length - 1) AppSpacing.gapMD,
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.currency});

  final TransactionModel transaction;
  final NumberFormat currency;

  IconData get icon {
    switch (transaction.category) {
      case TransactionCategory.food:
        return LucideIcons.utensils;

      case TransactionCategory.shopping:
        return LucideIcons.shoppingBag;

      case TransactionCategory.salary:
        return LucideIcons.wallet;

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

  Color get color {
    return transaction.isIncome ? AppColors.success : AppColors.primary;
  }

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
              Text(transaction.category.name, style: AppTypography.bodySmall),
            ],
          ),
        ),

        Text(
          '${transaction.isIncome ? '+' : '-'}${currency.format(transaction.amount)}',
          style: AppTypography.labelLarge.copyWith(color: color),
        ),
      ],
    );
  }
}
