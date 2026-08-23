import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../forms/presentation/money_form_page.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../models/transaction_model.dart';

class RecentTransactionCard extends ConsumerWidget {
  const RecentTransactionCard({super.key, required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = transactions.take(3).toList();
    final wallets = ref.watch(visibleWalletsProvider);

    return NexoraSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexoraSectionHeader(
            title: 'Transaksi terbaru',
            actionLabel: 'Lihat semua',
            onAction: () => context.go('/transactions'),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (recent.isEmpty)
            NexoraEmpty(
              icon: LucideIcons.receipt,
              title: 'Belum ada transaksi',
              reason: 'Catat pemasukan atau pengeluaran pertamamu.',
              ctaLabel: 'Tambah transaksi',
              onPressed: () => NexoraTransactionChooser.show(
                context,
                onIncome: () => context.push('/add-income'),
                onExpense: () => context.push('/add-expense'),
              ),
            )
          else
            for (final transaction in recent)
              NexoraTransactionTile(
                title: transaction.title,
                amount: transaction.amount,
                type: transaction.isIncome
                    ? NexoraTransactionType.income
                    : transaction.isTransfer
                        ? NexoraTransactionType.transfer
                        : NexoraTransactionType.expense,
                category: transaction.category.labelId,
                date: DateFormat('d MMM', 'id_ID').format(transaction.date),
                onTap: () => _openDetail(context, ref, transaction, wallets),
              ),
        ],
      ),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    TransactionModel transaction,
    List wallets,
  ) async {
    await NexoraTransactionDetail.show(
      context,
      transaction: transaction,
      walletName: NexoraTransactionDetail.walletNameFor(transaction, ref.read(visibleWalletsProvider)),
      onEdit: transaction.isTransfer
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MoneyFormPage(income: transaction.isIncome, transaction: transaction),
                ),
              );
            },
      onDelete: () async {
        final confirmed = await NexoraDialog.confirm(
          context,
          title: 'Hapus transaksi?',
          message: 'Hapus ${transaction.title} sebesar ${rupiah(transaction.amount)}?',
          confirmLabel: 'Hapus',
          danger: true,
        );
        if (!confirmed) return;
        await ref.read(financialTransactionStoreProvider.notifier).delete(transaction.id);
      },
    );
  }
}
