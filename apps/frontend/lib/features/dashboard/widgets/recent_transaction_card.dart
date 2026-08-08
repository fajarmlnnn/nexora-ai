import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/layout/n_section_header.dart';
import '../../../core/widgets/premium_widgets.dart';

import '../models/transaction_model.dart';

class RecentTransactionCard extends StatelessWidget {
  const RecentTransactionCard({super.key, required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final recent = transactions.take(4).toList();

    return NCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NSectionHeader(
            title: "Recent Transactions",
            actionLabel: "See All",
            onActionPressed: () {},
          ),

          AppSpacing.gapMD,

          if (recent.isEmpty)
            const _EmptyTransactions()
          else
            for (int i = 0; i < recent.length; i++) ...[
              PremiumEntrance(
                delay: Duration(milliseconds: i * 70),
                child: _TransactionTile(transaction: recent[i]),
              ),

              if (i != recent.length - 1) ...[
                const SizedBox(height: 12),

                Divider(height: 1, color: Colors.white.withValues(alpha: .05)),

                const SizedBox(height: 12),
              ],
            ],
        ],
      ),
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

      case TransactionCategory.transport:
        return LucideIcons.car;

      case TransactionCategory.shopping:
        return LucideIcons.shoppingBag;

      case TransactionCategory.salary:
        return LucideIcons.badgeDollarSign;

      case TransactionCategory.investment:
        return LucideIcons.chartColumn;

      case TransactionCategory.bills:
        return LucideIcons.receipt;

      case TransactionCategory.entertainment:
        return LucideIcons.film;

      case TransactionCategory.health:
        return LucideIcons.heartPulse;

      case TransactionCategory.education:
        return LucideIcons.graduationCap;

      case TransactionCategory.other:
        return LucideIcons.circleDollarSign;
    }
  }

  Color get color =>
      transaction.isIncome ? AppColors.success : AppColors.danger;

  String get dateLabel {
    final now = DateTime.now();

    if (DateUtils.isSameDay(now, transaction.date)) {
      return "Today";
    }

    if (DateUtils.isSameDay(
      now.subtract(const Duration(days: 1)),
      transaction.date,
    )) {
      return "Yesterday";
    }

    return DateFormat("dd MMM").format(transaction.date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.radiusLG,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadows.soft,
              ),
              child: Icon(icon, size: 20, color: color),
            ),

            AppSpacing.hGapMD,

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "$dateLabel • ${transaction.isIncome ? "Income" : "Expense"}",
                    style: AppTypography.caption.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${transaction.isIncome ? "+" : "-"}${rupiah(transaction.amount)}",
                  style: AppTypography.labelLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Icon(
                  transaction.isIncome
                      ? LucideIcons.arrowDownLeft
                      : LucideIcons.arrowUpRight,
                  size: 14,
                  color: color.withValues(alpha: .80),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.receipt,
              color: AppColors.primary,
              size: 30,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            "Belum Ada Transaksi",
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Tambah transaksi pertama untuk mulai\nmelacak keuanganmu.",
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white60,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 18),

          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text("Tambah Transaksi"),
          ),
        ],
      ),
    );
  }
}
