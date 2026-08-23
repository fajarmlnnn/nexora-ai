import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../features/dashboard/models/transaction_model.dart';
import '../../../features/wallet/models/wallet_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/money_input.dart';
import 'nexora_amount.dart';
import 'nexora_button.dart';
import 'nexora_sheet.dart';

class NexoraTransactionDetail {
  const NexoraTransactionDetail._();

  static Future<void> show(
    BuildContext context, {
    required TransactionModel transaction,
    String? walletName,
    String? sourceWalletName,
    String? destinationWalletName,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return NexoraSheet.show<void>(
      context: context,
      title: 'Detail transaksi',
      overline: transaction.type.labelId,
      child: _NexoraTransactionDetailBody(
        transaction: transaction,
        walletName: walletName,
        sourceWalletName: sourceWalletName,
        destinationWalletName: destinationWalletName,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  static String walletNameFor(TransactionModel transaction, List<WalletModel> wallets) {
    final id = transaction.walletId;
    if (id == null || id.isEmpty) return 'Wallet tidak diketahui';
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet.name;
    }
    return 'Wallet';
  }
}

class _NexoraTransactionDetailBody extends StatelessWidget {
  const _NexoraTransactionDetailBody({
    required this.transaction,
    this.walletName,
    this.sourceWalletName,
    this.destinationWalletName,
    this.onEdit,
    this.onDelete,
  });

  final TransactionModel transaction;
  final String? walletName;
  final String? sourceWalletName;
  final String? destinationWalletName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final occurred = DateFormat('EEEE, d MMMM yyyy • HH.mm', 'id_ID').format(transaction.date);
    final direction = transaction.isIncome
        ? NexoraAmountDirection.income
        : transaction.isTransfer
            ? NexoraAmountDirection.transfer
            : NexoraAmountDirection.expense;

    return Semantics(
      label: '${transaction.title}, ${transaction.type.labelId}, ${spokenRupiah(transaction.amount)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NexoraAmount(amount: transaction.amount, role: NexoraAmountRole.hero, direction: direction, showSign: true),
          const SizedBox(height: AppSpacing.sm),
          Text(transaction.title, style: AppTypography.heading3),
          const SizedBox(height: AppSpacing.xl),
          _Row(label: 'Jenis', value: transaction.type.labelId),
          _Row(label: 'Kategori', value: transaction.category.labelId),
          _Row(label: 'Waktu', value: occurred),
          if (walletName != null && walletName!.isNotEmpty) _Row(label: 'Wallet', value: walletName!),
          if (transaction.isTransfer) ...[
            _Row(label: 'Dari', value: sourceWalletName ?? transaction.sourceAccount ?? '-'),
            _Row(label: 'Ke', value: destinationWalletName ?? transaction.destinationAccount ?? '-'),
          ],
          if (transaction.note != null && transaction.note!.trim().isNotEmpty)
            _Row(label: 'Catatan', value: transaction.note!.trim()),
          const SizedBox(height: AppSpacing.xl),
          if (onEdit != null && !transaction.isTransfer)
            NexoraButton(
              label: 'Ubah',
              icon: const Icon(LucideIcons.pencil, size: 18),
              variant: NexoraButtonVariant.secondary,
              onPressed: () {
                Navigator.of(context).pop();
                onEdit!();
              },
            ),
          if (onEdit != null && onDelete != null && !transaction.isTransfer)
            const SizedBox(height: AppSpacing.sm),
          if (onDelete != null)
            NexoraButton(
              label: 'Hapus',
              icon: const Icon(LucideIcons.trash2, size: 18),
              variant: NexoraButtonVariant.danger,
              onPressed: () {
                Navigator.of(context).pop();
                onDelete!();
              },
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: AppTypography.caption)),
          Expanded(child: Text(value, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class NexoraTransactionChooser {
  const NexoraTransactionChooser._();

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onIncome,
    required VoidCallback onExpense,
  }) {
    return NexoraSheet.show<void>(
      context: context,
      title: 'Tambah transaksi',
      overline: 'Pilih jenis',
      child: Column(
        children: [
          NexoraButton(
            label: 'Pemasukan',
            icon: const Icon(LucideIcons.arrowDownLeft, size: 18),
            onPressed: () {
              Navigator.of(context).pop();
              onIncome();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          NexoraButton(
            label: 'Pengeluaran',
            icon: const Icon(LucideIcons.arrowUpRight, size: 18),
            variant: NexoraButtonVariant.secondary,
            onPressed: () {
              Navigator.of(context).pop();
              onExpense();
            },
          ),
        ],
      ),
    );
  }
}
