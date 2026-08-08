import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NSectionHeader(
            title: 'Recent Transactions',
            actionLabel: 'See All',
            onActionPressed: () => context.go('/transactions'),
          ),
          const SizedBox(height: 6),
          if (recent.isEmpty)
            const _EmptyTransactions()
          else
            for (int i = 0; i < recent.length; i++) ...[
              PremiumEntrance(
                delay: Duration(milliseconds: i * 45),
                child: _TransactionTile(transaction: recent[i]),
              ),
              if (i != recent.length - 1)
                Divider(height: 1, color: Colors.white.withValues(alpha: .055)),
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
    if (DateUtils.isSameDay(now, transaction.date)) return 'Hari ini';
    if (DateUtils.isSameDay(now.subtract(const Duration(days: 1)), transaction.date)) return 'Kemarin';
    return DateFormat('dd MMM', 'id_ID').format(transaction.date);
  }

  String get categoryLabel {
    return switch (transaction.category) {
      TransactionCategory.food => 'Makanan',
      TransactionCategory.transport => 'Transportasi',
      TransactionCategory.shopping => 'Belanja',
      TransactionCategory.salary => 'Gaji',
      TransactionCategory.investment => 'Investasi',
      TransactionCategory.bills => 'Tagihan',
      TransactionCategory.entertainment => 'Hiburan',
      TransactionCategory.health => 'Kesehatan',
      TransactionCategory.education => 'Pendidikan',
      TransactionCategory.other => 'Lainnya',
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.radiusLG,
      onTap: () => context.go('/transactions'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .10),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: .10)),
                boxShadow: AppShadows.soft,
              ),
              child: Icon(
                transaction.isIncome ? LucideIcons.arrowDownLeft : icon,
                size: 17,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          categoryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '•',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      Text(
                        dateLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.isIncome ? '+' : '-'}${rupiah(transaction.amount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    transaction.isIncome ? 'Masuk' : 'Keluar',
                    style: AppTypography.caption.copyWith(
                      color: accent,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.receipt,
              color: AppColors.primaryLight,
              size: 24,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Belum Ada Transaksi',
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Catat transaksi pertamamu untuk mulai\nmelacak keuangan dengan Nexora.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/transactions'),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Tambah Transaksi'),
          ),
        ],
      ),
    );
  }
}
