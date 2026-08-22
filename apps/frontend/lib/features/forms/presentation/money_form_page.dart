import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../../wallet/models/wallet_model.dart';

class MoneyFormPage extends ConsumerStatefulWidget {
  const MoneyFormPage({super.key, required this.income, this.transaction});
  final bool income;
  final TransactionModel? transaction;
  bool get isEditing => transaction != null;
  @override
  ConsumerState<MoneyFormPage> createState() => _MoneyFormPageState();
}

class _MoneyFormPageState extends ConsumerState<MoneyFormPage> {
  late final TextEditingController _amountController;
  final _titleController = TextEditingController();
  late TransactionCategory _category;
  String? _walletId;
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(text: tx == null ? '' : _formatAmount(tx.amount));
    _titleController.text = tx?.title ?? (widget.income ? 'Pemasukan' : 'Pengeluaran');
    _category = tx?.category ?? (widget.income ? TransactionCategory.salary : TransactionCategory.food);
    _walletId = tx?.walletId;
    _selectedDate = tx?.date ?? DateTime.now();
  }

  String _formatAmount(double amount) => amount == amount.roundToDouble() ? amount.toInt().toString() : amount.toString();

  @override
  void dispose() { _amountController.dispose(); _titleController.dispose(); super.dispose(); }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amount == null || amount <= 0) return _showError('Masukkan jumlah yang valid.');
    final wallets = ref.read(visibleWalletsProvider);
    final walletId = _walletId ?? ref.read(primaryWalletProvider)?.id;
    if (walletId == null || wallets.isEmpty) return _showError('Pilih wallet terlebih dahulu.');
    setState(() => _saving = true);
    try {
      final previous = widget.transaction;
      final tx = TransactionModel(
        id: previous?.id ?? 'tx-${DateTime.now().microsecondsSinceEpoch}',
        title: _titleController.text.trim().isEmpty ? (widget.income ? 'Pemasukan' : 'Pengeluaran') : _titleController.text.trim(),
        amount: amount,
        type: widget.income ? TransactionType.income : TransactionType.expense,
        category: _category,
        date: DateUtils.dateOnly(_selectedDate),
        walletId: walletId,
        note: previous?.note,
      );
      final store = ref.read(financialTransactionStoreProvider.notifier);
      if (previous == null) { await store.add(tx); } else { await store.replace(tx); }
      if (mounted) Navigator.pop(context, tx);
    } catch (error) {
      if (mounted) _showError('Gagal menyimpan transaksi: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(_selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 10, 12, 31),
      helpText: widget.income ? 'Pilih tanggal pemasukan' : 'Pilih tanggal pengeluaran',
      cancelText: 'Batal', confirmText: 'Pilih',
      builder: (dialogContext, child) => Theme(
        data: Theme.of(dialogContext).copyWith(
          brightness: Brightness.dark,
          colorScheme: Theme.of(dialogContext).colorScheme.copyWith(primary: AppColors.primaryLight, surface: AppColors.card),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.card, surfaceTintColor: Colors.transparent),
        ),
        child: child!,
      ),
    );
    if (mounted && picked != null) setState(() => _selectedDate = DateUtils.dateOnly(picked));
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final accent = widget.income ? AppColors.success : AppColors.danger;
    final walletsAsync = ref.watch(walletProvider);
    final wallets = ref.watch(visibleWalletsProvider);
    final selectedWallet = _selectedWallet(wallets);
    final title = widget.isEditing ? (widget.income ? 'Edit Pemasukan' : 'Edit Pengeluaran') : (widget.income ? 'Tambah Pemasukan' : 'Tambah Pengeluaran');
    return PremiumScaffold(
      bottomPadding: false,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.arrowLeft)), const SizedBox(width: 4), Expanded(child: Text(title, style: AppTypography.heading2)), const _SecureBadge()]),
          const SizedBox(height: 18),
          PremiumCard(
            borderRadius: AppRadius.radiusXXL,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            gradient: LinearGradient(colors: [accent.withValues(alpha: .20), AppColors.card.withValues(alpha: .88)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: .16)), child: Icon(widget.income ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, color: accent)), const SizedBox(width: 12), Expanded(child: Text(widget.income ? 'Money in' : 'Money out', style: AppTypography.labelLarge))]),
              const SizedBox(height: 18),
              TextField(controller: _amountController, autofocus: !widget.isEditing, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: AppTypography.display.copyWith(fontSize: 34, fontWeight: FontWeight.w800), decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0', border: InputBorder.none, isDense: true)),
              Text(widget.income ? 'Catat pemasukan secara konsisten.' : 'Pantau pengeluaran sebelum budget bocor.', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ]),
          ),
          const SizedBox(height: 18),
          _InputCard(label: 'Nama transaksi', controller: _titleController, hint: widget.income ? 'Contoh: Gaji' : 'Contoh: Makan siang'),
          _SelectionCard(label: 'Kategori', value: _categoryLabel(_category), onTap: _selectCategory),
          _SelectionCard(label: 'Wallet', value: walletsAsync.isLoading ? 'Memuat wallet...' : selectedWallet?.name ?? 'Pilih wallet', onTap: wallets.isEmpty ? null : _selectWallet),
          _SelectionCard(label: 'Tanggal', value: DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate), onTap: _selectDate),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.check), label: Text(_saving ? 'Menyimpan...' : widget.isEditing ? 'Simpan Perubahan' : 'Simpan Transaksi'), style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL))),
          const SizedBox(height: 12),
          Text('Transaksi akan memperbarui saldo dan ringkasan keuangan secara otomatis.', textAlign: TextAlign.center, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  WalletModel? _selectedWallet(List<WalletModel> wallets) {
    final id = _walletId ?? ref.read(primaryWalletProvider)?.id;
    for (final wallet in wallets) { if (wallet.id == id) return wallet; }
    return null;
  }

  Future<void> _selectWallet() async {
    final wallets = ref.read(visibleWalletsProvider);
    final selected = await showModalBottomSheet<String>(context: context, backgroundColor: AppColors.card, showDragHandle: true, builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [for (final wallet in wallets) ListTile(leading: Icon(wallet.icon, color: wallet.color), title: Text(wallet.name), subtitle: Text(wallet.maskedAccount), trailing: wallet.id == (_walletId ?? ref.read(primaryWalletProvider)?.id) ? const Icon(LucideIcons.check, color: AppColors.primaryLight) : null, onTap: () => Navigator.pop(context, wallet.id))])));
    if (selected != null) setState(() => _walletId = selected);
  }

  Future<void> _selectCategory() async {
    final selected = await showModalBottomSheet<TransactionCategory>(context: context, backgroundColor: AppColors.card, showDragHandle: true, builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [for (final category in TransactionCategory.values) ListTile(title: Text(_categoryLabel(category)), trailing: category == _category ? const Icon(LucideIcons.check, color: AppColors.primaryLight) : null, onTap: () => Navigator.pop(context, category))])));
    if (selected != null) setState(() => _category = selected);
  }

  String _categoryLabel(TransactionCategory category) => switch (category) {
    TransactionCategory.food => 'Makan & Minum', TransactionCategory.transport => 'Transportasi', TransactionCategory.shopping => 'Belanja', TransactionCategory.salary => 'Gaji', TransactionCategory.investment => 'Investasi', TransactionCategory.bills => 'Tagihan', TransactionCategory.entertainment => 'Hiburan', TransactionCategory.health => 'Kesehatan', TransactionCategory.education => 'Pendidikan', TransactionCategory.other => 'Lainnya',
  };
}

class _SecureBadge extends StatelessWidget {
  const _SecureBadge();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .10), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.success.withValues(alpha: .22))), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.shieldCheck, size: 13, color: AppColors.success), SizedBox(width: 5), Text('Secure', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]));
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.label, required this.controller, required this.hint});
  final String label; final TextEditingController controller; final String hint;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: PremiumCard(borderRadius: AppRadius.radiusXL, padding: const EdgeInsets.fromLTRB(16, 10, 16, 4), child: TextField(controller: controller, style: AppTypography.labelLarge, decoration: InputDecoration(labelText: label, hintText: hint, border: InputBorder.none))));
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.label, required this.value, this.onTap});
  final String label; final String value; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Material(color: Colors.transparent, child: InkWell(borderRadius: AppRadius.radiusXL, onTap: onTap, child: PremiumCard(borderRadius: AppRadius.radiusXL, padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTypography.caption), const SizedBox(height: 4), Text(value, style: AppTypography.labelLarge)])), const Icon(LucideIcons.chevronDown, color: AppColors.textMuted)])))));
}
