import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final recent = transactions.take(3).toList();

    return NCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NSectionHeader(
            title: 'Recent Transactions',
            actionLabel: 'See All',
            onActionPressed: () => context.go('/transactions'),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const _EmptyTransactions()
          else
            for (int i = 0; i < recent.length; i++) ...[
              PremiumEntrance(
                delay: Duration(milliseconds: i * 60),
                child: _TransactionTile(transaction: recent[i]),
              ),
              if (i != recent.length - 1) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.white.withValues(alpha: .05)),
                const SizedBox(height: 10),
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
    return switch (transaction.category) {
      TransactionCategory.food => LucideIcons.utensils,
      TransactionCategory.transport => LucideIcons.car,
      TransactionCategory.shopping => LucideIcons.shoppingBag,
      TransactionCategory.salary => LucideIcons.badgeDollarSign,
      TransactionCategory.investment => LucideIcons.chartColumn,
      TransactionCategory.bills => LucideIcons.receipt,
      TransactionCategory.entertainment => LucideIcons.film,
      TransactionCategory.health => LucideIcons.heartPulse,
      TransactionCategory.education => LucideIcons.graduationCap,
      TransactionCategory.other => LucideIcons.circleDollarSign,
    };
  }

  Color get accent => transaction.isIncome ? AppColors.success : AppColors.danger;

  String get dateLabel {
    final now = DateTime.now();

    if (DateUtils.isSameDay(now, transaction.date)) {
      return 'Hari ini';
    }

    if (DateUtils.isSameDay(
      now.subtract(const Duration(days: 1)),
      transaction.date,
    )) {
      return 'Kemarin';
    }

    return DateFormat('dd MMM', 'id_ID').format(transaction.date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.radiusLG,
      onTap: () => context.go('/transactions'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(13),
                boxShadow: AppShadows.soft,
              ),
              child: Icon(icon, size: 19, color: accent),
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
                  const SizedBox(height: 3),
                  Text(
                    '$dateLabel • ${transaction.isIncome ? 'Pemasukan' : 'Pengeluaran'}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.isIncome ? '+' : '-'}${rupiah(transaction.amount)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Icon(
                  transaction.isIncome
                      ? LucideIcons.arrowDownLeft
                      : LucideIcons.arrowUpRight,
                  size: 13,
                  color: accent.withValues(alpha: .75),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.receipt,
              color: AppColors.primaryLight,
              size: 27,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Transaksi',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Catat transaksi pertamamu untuk mulai\nmelacak keuangan dengan Nexora.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/transactions'),
            icon: const Icon(LucideIcons.plus, size: 17),
            label: const Text('Tambah Transaksi'),
          ),
        ],
      ),
    );
  }
}
