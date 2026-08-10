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
    final recent = transactions.take(3).toList();

    return NCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Recent Transactions', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700))),
              TextButton(
                onPressed: () => context.push('/transactions'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text('See All  ›', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (recent.isEmpty)
            const _EmptyTransactions()
          else
            for (int i = 0; i < recent.length; i++) ...[
              PremiumEntrance(delay: Duration(milliseconds: i * 45), child: _TransactionTile(transaction: recent[i])),
              if (i != recent.length - 1) Divider(height: 1, indent: 54, color: Colors.white.withValues(alpha: .055)),
            ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final TransactionModel transaction;

  IconData get icon => switch (transaction.category) {
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

  Color get accent => transaction.isIncome ? AppColors.success : AppColors.danger;

  String get dateLabel {
    final now = DateTime.now();
    if (DateUtils.isSameDay(now, transaction.date)) return 'Hari ini';
    if (DateUtils.isSameDay(now.subtract(const Duration(days: 1)), transaction.date)) return 'Kemarin';
    return DateFormat('dd MMM', 'id_ID').format(transaction.date);
  }

  String get categoryLabel => switch (transaction.category) {
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
      onTap: () => context.push('/transactions'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            _TransactionIcon(icon: transaction.isIncome ? LucideIcons.arrowDownLeft : icon, color: accent),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(child: Text(categoryLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 9.5))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Text('•', style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 8))),
                      Text(dateLabel, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 9.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 108),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text('${transaction.isIncome ? '+' : '-'}${rupiah(transaction.amount)}', maxLines: 1, softWrap: false, style: AppTypography.labelMedium.copyWith(color: accent, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 5, height: 5, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(transaction.isIncome ? 'Masuk' : 'Keluar', style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 7.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionIcon extends StatelessWidget {
  const _TransactionIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: color.withValues(alpha: .10), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: .10))),
        child: Icon(icon, size: 18, color: color),
      );
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 205,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .10), shape: BoxShape.circle),
                child: const Icon(LucideIcons.receipt, color: AppColors.primaryLight, size: 24),
              ),
              const SizedBox(height: 9),
              Text('Belum Ada Transaksi', textAlign: TextAlign.center, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Catat transaksi pertamamu untuk mulai\nmelacak keuangan dengan Nexora.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.push('/transactions'),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Tambah Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
