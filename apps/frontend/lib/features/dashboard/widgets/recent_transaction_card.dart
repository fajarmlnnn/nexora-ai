import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../models/transaction_model.dart';

class RecentTransactionCard extends StatelessWidget {
  const RecentTransactionCard({super.key, required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final recent = transactions.take(4).toList();

    return NCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      showBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .10),
                  borderRadius: AppRadius.radiusMD,
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: .10),
                  ),
                ),
                child: const Icon(
                  LucideIcons.receiptText,
                  color: AppColors.primaryLight,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent transactions',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recent.isEmpty
                          ? 'Belum ada aktivitas'
                          : '${recent.length} aktivitas terbaru',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go('/transactions'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat semua',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: AppColors.primaryLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const _EmptyTransactions()
          else
            for (int i = 0; i < recent.length; i++) ...[
              PremiumEntrance(
                delay: Duration(milliseconds: i * 45),
                child: _TransactionTile(transaction: recent[i]),
              ),
              if (i != recent.length - 1)
                Divider(
                  height: 1,
                  indent: 52,
                  color: Colors.white.withValues(alpha: .055),
                ),
            ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionModel transaction;

  IconData get _categoryIcon => switch (transaction.category) {
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

  Color get _accent => transaction.isTransfer
      ? AppColors.info
      : transaction.isIncome
          ? AppColors.success
          : AppColors.danger;

  IconData get _icon => transaction.isTransfer
      ? LucideIcons.arrowLeftRight
      : transaction.isIncome
          ? LucideIcons.arrowDownLeft
          : _categoryIcon;

  String get _dateLabel {
    final now = DateTime.now();
    if (DateUtils.isSameDay(now, transaction.date)) return 'Hari ini';
    if (DateUtils.isSameDay(
      now.subtract(const Duration(days: 1)),
      transaction.date,
    )) {
      return 'Kemarin';
    }
    return DateFormat('dd MMM', 'id_ID').format(transaction.date);
  }

  String get _categoryLabel => switch (transaction.category) {
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.radiusLG,
      onTap: () => context.go('/transactions'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: .09),
                shape: BoxShape.circle,
                border: Border.all(color: _accent.withValues(alpha: .12)),
              ),
              child: Icon(_icon, size: 17, color: _accent),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.isTransfer ? 'Transfer' : _categoryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 9.5,
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
                        _dateLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 9.5,
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    transaction.isTransfer
                        ? rupiah(transaction.amount)
                        : '${transaction.isIncome ? '+' : '-'}${rupiah(transaction.amount)}',
                    maxLines: 1,
                    softWrap: false,
                    style: AppTypography.labelMedium.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      transaction.isTransfer
                          ? 'Transfer'
                          : transaction.isIncome
                              ? 'Masuk'
                              : 'Keluar',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
    return SizedBox(
      width: double.infinity,
      height: 152,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.receipt,
                color: AppColors.primaryLight,
                size: 21,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada transaksi',
              textAlign: TextAlign.center,
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              'Catat transaksi pertamamu untuk mulai\nmembangun pola finansial Nexora.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => context.go('/transactions'),
              icon: const Icon(LucideIcons.plus, size: 15),
              label: const Text('Tambah transaksi'),
            ),
          ],
        ),
      ),
    );
  }
}
