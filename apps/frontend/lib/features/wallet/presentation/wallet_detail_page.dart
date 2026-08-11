import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_model.dart';

class WalletDetailPage extends ConsumerWidget {
  const WalletDetailPage({super.key, required this.walletId});
  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletProvider);
    final wallet = wallets.valueOrNull?.cast<WalletModel?>().firstWhere((item) => item?.id == walletId, orElse: () => null);
    if (wallet == null) {
      return PremiumScaffold(child: Center(child: Padding(padding: AppSpacing.screen, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(LucideIcons.walletMinimal, size: 44, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text('Wallet tidak ditemukan', style: AppTypography.heading3),
        const SizedBox(height: 6),
        Text('Wallet mungkin sudah dihapus atau disembunyikan.', textAlign: TextAlign.center, style: AppTypography.bodySmall),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kembali')),
      ]))));
    }

    final transactions = ref.watch(financialTransactionStoreProvider);
    final related = transactions.where((tx) => tx.walletId == wallet.id || tx.sourceAccount == wallet.id || tx.destinationAccount == wallet.id).toList()..sort((a, b) => b.date.compareTo(a.date));
    final now = DateTime.now();
    final monthTransactions = related.where((tx) => tx.date.year == now.year && tx.date.month == now.month).toList();
    var income = 0.0;
    var expense = 0.0;
    var transferIn = 0.0;
    var transferOut = 0.0;
    var monthIncome = 0.0;
    var monthExpense = 0.0;
    var monthTransferIn = 0.0;
    var monthTransferOut = 0.0;

    for (final tx in related) {
      if (tx.isIncome) income += tx.amount;
      if (tx.isExpense) expense += tx.amount;
      if (tx.isTransfer) {
        if (tx.destinationAccount == wallet.id) transferIn += tx.amount;
        if (tx.sourceAccount == wallet.id) transferOut += tx.amount;
      }
    }
    for (final tx in monthTransactions) {
      if (tx.isIncome) monthIncome += tx.amount;
      if (tx.isExpense) monthExpense += tx.amount;
      if (tx.isTransfer) {
        if (tx.destinationAccount == wallet.id) monthTransferIn += tx.amount;
        if (tx.sourceAccount == wallet.id) monthTransferOut += tx.amount;
      }
    }

    final monthNet = monthIncome - monthExpense;
    final spending = <TransactionCategory, double>{};
    final spendingCounts = <TransactionCategory, int>{};
    for (final tx in monthTransactions.where((tx) => tx.isExpense)) {
      spending[tx.category] = (spending[tx.category] ?? 0) + tx.amount;
      spendingCounts[tx.category] = (spendingCounts[tx.category] ?? 0) + 1;
    }
    final topSpending = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final accent = _walletAccent(wallet.type);

    return PremiumScaffold(child: SafeArea(child: ListView(padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 24), children: [
      Row(children: [
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(LucideIcons.arrowLeft)),
        Expanded(child: Text(wallet.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w800))),
        IconButton(onPressed: () => _showActions(context, ref, wallet), icon: const Icon(LucideIcons.ellipsis)),
      ]),
      const SizedBox(height: 8),
      PremiumCard(padding: const EdgeInsets.all(18), borderRadius: AppRadius.radiusXXL, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: accent.withValues(alpha: .12), borderRadius: AppRadius.radiusLG), child: Icon(wallet.icon, color: accent, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(wallet.bankName, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)), Text(wallet.maskedAccount, style: AppTypography.caption)])),
          if (wallet.isPrimary) const _StatusChip(label: 'PRIMARY', color: AppColors.primaryLight),
        ]),
        const SizedBox(height: 20),
        Text('Saldo', style: AppTypography.caption),
        const SizedBox(height: 4),
        FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(rupiah(wallet.balance), style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.w900, color: Colors.white))),
      ])),
      const SizedBox(height: 14),
      _AiCard(wallet: wallet, net: monthNet, topSpending: topSpending.isEmpty ? null : topSpending.first),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _MetricCard(title: 'Pemasukan', amount: income, color: AppColors.success, icon: LucideIcons.arrowDownLeft)),
        const SizedBox(width: 10),
        Expanded(child: _MetricCard(title: 'Pengeluaran', amount: expense, color: AppColors.danger, icon: LucideIcons.arrowUpRight)),
      ]),
      const SizedBox(height: 10),
      PremiumCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Arus Uang', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _FlowRow(label: 'Net cashflow', amount: income - expense, color: income >= expense ? AppColors.success : AppColors.danger),
        _FlowRow(label: 'Transfer masuk', amount: transferIn, color: AppColors.info),
        _FlowRow(label: 'Transfer keluar', amount: transferOut, color: AppColors.warning),
      ])),
      const SizedBox(height: 14),
      _ActivityCard(income: monthIncome, expense: monthExpense, transferIn: monthTransferIn, transferOut: monthTransferOut),
      const SizedBox(height: 14),
      PremiumCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pengeluaran Terbesar', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (topSpending.isEmpty) Text('Belum cukup data pengeluaran bulan ini.', style: AppTypography.caption)
        else ...topSpending.take(3).map((entry) => _FlowRow(label: entry.key.name, amount: entry.value, color: AppColors.danger)),
      ])),
      const SizedBox(height: 18),
      Row(children: [Expanded(child: Text('Transaksi Terbaru', style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800))), Text('${related.length} transaksi', style: AppTypography.caption)]),
      const SizedBox(height: 8),
      if (related.isEmpty) PremiumCard(padding: const EdgeInsets.all(18), child: Text('Belum ada transaksi pada wallet ini.', textAlign: TextAlign.center, style: AppTypography.bodySmall))
      else ...related.take(12).map((tx) => _TransactionRow(transaction: tx, walletId: wallet.id)),
      const SizedBox(height: 18),
      Text('Informasi Wallet', style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      PremiumCard(padding: const EdgeInsets.all(14), child: Column(children: [
        _InfoRow(label: 'Nama wallet', value: wallet.name),
        _InfoRow(label: 'Tipe', value: _walletTypeLabel(wallet.type)),
        _InfoRow(label: 'Bank / provider', value: wallet.bankName),
        _InfoRow(label: 'Nomor akun', value: wallet.maskedAccount),
        _InfoRow(label: 'Status', value: wallet.isHidden ? 'Tersembunyi' : 'Aktif'),
      ])),
    ])));
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref, WalletModel wallet) async {
    await showModalBottomSheet<void>(context: context, backgroundColor: AppColors.card, builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(LucideIcons.star), title: Text(wallet.isPrimary ? 'Wallet utama' : 'Jadikan wallet utama'), enabled: !wallet.isPrimary, onTap: wallet.isPrimary ? null : () async { await ref.read(walletProvider.notifier).setPrimaryWallet(wallet.id); if (sheetContext.mounted) Navigator.pop(sheetContext); }),
      ListTile(leading: Icon(wallet.isHidden ? LucideIcons.eye : LucideIcons.eyeOff), title: Text(wallet.isHidden ? 'Tampilkan wallet' : 'Sembunyikan wallet'), onTap: () async { await ref.read(walletProvider.notifier).setWalletVisibility(wallet.id, hidden: !wallet.isHidden); if (sheetContext.mounted) Navigator.pop(sheetContext); }),
      ListTile(leading: const Icon(LucideIcons.trash2, color: AppColors.danger), title: const Text('Hapus wallet', style: TextStyle(color: AppColors.danger)), onTap: () async { Navigator.pop(sheetContext); await _confirmDelete(context, ref, wallet); }),
    ])));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, WalletModel wallet) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Hapus wallet?'), content: Text('Wallet ${wallet.name} akan dihapus dari daftar wallet.'), actions: [
      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
      FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
    ]));
    if (confirmed != true || !context.mounted) return;
    final success = await ref.read(walletProvider.notifier).deleteWallet(wallet.id);
    if (!context.mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet gagal dihapus.')));
    }
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.wallet, required this.net, this.topSpending});
  final WalletModel wallet;
  final double net;
  final MapEntry<TransactionCategory, double>? topSpending;
  @override
  Widget build(BuildContext context) {
    final positive = net >= 0;
    final insight = topSpending == null ? (positive ? 'Cashflow bulan ini positif berdasarkan transaksi yang tersedia.' : 'Cashflow bulan ini negatif berdasarkan transaksi yang tersedia.') : 'Pengeluaran terbesar bulan ini: ${_categoryLabel(topSpending!.key)} (${rupiah(topSpending!.value)}).';
    return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF17131F), Color(0xFF0D0D14)]), borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.primary.withValues(alpha: .24))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .14), borderRadius: AppRadius.radiusLG), child: const Icon(LucideIcons.sparkles, color: AppColors.primaryLight, size: 19)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text('Nexora AI', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)), const SizedBox(width: 6), const _StatusChip(label: 'AI', color: AppColors.primaryLight)]),
        const SizedBox(height: 5),
        Text(insight, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text('Analisis hanya menggunakan transaksi wallet ini pada bulan berjalan.', style: AppTypography.caption),
      ])),
    ]));
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.income, required this.expense, required this.transferIn, required this.transferOut});
  final double income;
  final double expense;
  final double transferIn;
  final double transferOut;
  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    final hasActivity = income != 0 || expense != 0 || transferIn != 0 || transferOut != 0;
    return PremiumCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Perubahan Bulan Ini', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))), Text('Bulan berjalan', style: AppTypography.caption)]),
      const SizedBox(height: 9),
      if (!hasActivity) Text('Belum ada perubahan tercatat bulan ini.', style: AppTypography.caption)
      else ...[
        _ActivityRow(label: 'Pemasukan', amount: income, color: AppColors.success, icon: LucideIcons.arrowDownLeft),
        _ActivityRow(label: 'Pengeluaran', amount: expense, color: AppColors.danger, icon: LucideIcons.arrowUpRight),
        _ActivityRow(label: 'Transfer masuk', amount: transferIn, color: AppColors.info, icon: LucideIcons.arrowDownLeft),
        _ActivityRow(label: 'Transfer keluar', amount: transferOut, color: AppColors.warning, icon: LucideIcons.arrowUpRight),
        const Divider(height: 14, color: AppColors.border),
        _ActivityRow(label: 'Net cashflow', amount: net, color: net >= 0 ? AppColors.success : AppColors.danger, icon: net >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown),
      ],
    ]));
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.label, required this.amount, required this.color, required this.icon});
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
    Container(width: 26, height: 26, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: AppRadius.radiusLG), child: Icon(icon, size: 14, color: color)),
    const SizedBox(width: 8),
    Expanded(child: Text(label, style: AppTypography.caption)),
    Text(rupiah(amount), style: AppTypography.amountSmall.copyWith(color: color, fontWeight: FontWeight.w800)),
  ]));
}

class _TopSpendingCard extends StatelessWidget {
  const _TopSpendingCard({required this.spending, required this.counts, required this.total});
  final List<MapEntry<TransactionCategory, double>> spending;
  final Map<TransactionCategory, int> counts;
  final double total;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Pengeluaran Terbesar', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))), Text('Bulan berjalan', style: AppTypography.caption)]),
      const SizedBox(height: 10),
      if (spending.isEmpty || total <= 0)
        Text('Belum cukup data pengeluaran bulan ini.', style: AppTypography.caption)
      else
        ...spending.take(3).map((entry) {
          final percentage = (entry.value / total).clamp(0.0, 1.0);
          final count = counts[entry.key] ?? 0;
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(_categoryLabel(entry.key), style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700))),
              Text('${(percentage * 100).round()}%', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 5),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: percentage, minHeight: 5, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight))),
            const SizedBox(height: 5),
            Row(children: [Expanded(child: Text('${rupiah(entry.value)} • $count transaksi', style: AppTypography.caption)), if (entry == spending.first) const _StatusChip(label: 'TERBESAR', color: AppColors.primaryLight)]),
          ]));
        }),
    ]));
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.amount, required this.color, required this.icon});
  final String title; final double amount; final Color color; final IconData icon;
  @override
  Widget build(BuildContext context) => PremiumCard(padding: const EdgeInsets.all(13), child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: AppRadius.radiusLG), child: Icon(icon, size: 16, color: color)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTypography.caption), const SizedBox(height: 2), Text(rupiah(amount), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))]))]));
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({required this.label, required this.amount, required this.color});
  final String label; final double amount; final Color color;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label, style: AppTypography.caption)), Text(rupiah(amount), style: AppTypography.amountSmall.copyWith(color: color, fontWeight: FontWeight.w800))]));
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.walletId});
  final TransactionModel transaction; final String walletId;
  @override
  Widget build(BuildContext context) {
    final incoming = transaction.isIncome || (transaction.isTransfer && transaction.destinationAccount == walletId);
    final color = transaction.isTransfer ? AppColors.info : (incoming ? AppColors.success : AppColors.danger);
    final sign = incoming ? '+' : '-';
    return Padding(padding: const EdgeInsets.only(bottom: 7), child: PremiumCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: AppRadius.radiusLG), child: Icon(transaction.isTransfer ? LucideIcons.arrowLeftRight : (incoming ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight), size: 17, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(transaction.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)), Text('${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.year}', style: AppTypography.caption)])),
      Text('$sign${rupiah(transaction.amount)}', style: AppTypography.amountSmall.copyWith(color: color, fontWeight: FontWeight.w800)),
    ])));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label; final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: AppTypography.caption)), const SizedBox(width: 12), Flexible(child: Text(value, textAlign: TextAlign.right, style: AppTypography.amountSmall.copyWith(fontWeight: FontWeight.w700)))]));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label; final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)));
}

String _categoryLabel(TransactionCategory category) {
  switch (category) {
    case TransactionCategory.salary:
      return 'Gaji';
    case TransactionCategory.food:
      return 'Makanan';
    case TransactionCategory.transport:
      return 'Transportasi';
    case TransactionCategory.shopping:
      return 'Belanja';
    case TransactionCategory.bills:
      return 'Tagihan';
    case TransactionCategory.health:
      return 'Kesehatan';
    case TransactionCategory.entertainment:
      return 'Hiburan';
    case TransactionCategory.education:
      return 'Pendidikan';
    case TransactionCategory.investment:
      return 'Investasi';
    case TransactionCategory.other:
      return 'Lainnya';
  }
}

Color _walletAccent(WalletType type) {
  switch (type) {
    case WalletType.bank: return AppColors.primary;
    case WalletType.ewallet: return AppColors.info;
    case WalletType.cash: return AppColors.warning;
    case WalletType.investment: return AppColors.success;
  }
}

String _walletTypeLabel(WalletType type) {
  switch (type) {
    case WalletType.bank: return 'Bank';
    case WalletType.ewallet: return 'E-Wallet';
    case WalletType.cash: return 'Cash';
    case WalletType.investment: return 'Investasi';
  }
}