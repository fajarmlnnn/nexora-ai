import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money_input.dart';
import '../../../core/utils/nexora_id.dart';
import '../../../core/widgets/nexora/nexora.dart';
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
  late final String _submitId;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _submitId = tx?.id ?? nexoraUuidV4();
    _amountController = TextEditingController(text: tx == null ? '' : _formatAmount(tx.amount));
    _titleController.text = tx?.title ?? (widget.income ? 'Pemasukan' : 'Pengeluaran');
    _category = tx?.category ?? (widget.income ? TransactionCategory.salary : TransactionCategory.food);
    _walletId = tx?.walletId;
    _selectedDate = tx?.date ?? DateTime.now();
  }

  String _formatAmount(double amount) => amount == amount.roundToDouble() ? amount.toInt().toString() : amount.toString();

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = parseRupiahInput(_amountController.text);
    if (amount == null) {
      NexoraToast.show(context, 'Masukkan jumlah yang valid.', error: true);
      return;
    }
    final wallets = ref.read(visibleWalletsProvider);
    final walletId = _walletId ?? ref.read(primaryWalletProvider)?.id;
    if (walletId == null || wallets.isEmpty) {
      NexoraToast.show(context, 'Pilih wallet terlebih dahulu.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final previous = widget.transaction;
      final tx = TransactionModel(
        id: _submitId,
        title: _titleController.text.trim().isEmpty ? (widget.income ? 'Pemasukan' : 'Pengeluaran') : _titleController.text.trim(),
        amount: amount,
        type: widget.income ? TransactionType.income : TransactionType.expense,
        category: _category,
        date: DateUtils.dateOnly(_selectedDate),
        walletId: walletId,
        note: previous?.note,
      );
      final store = ref.read(financialTransactionStoreProvider.notifier);
      if (previous == null) {
        await store.add(tx);
      } else {
        await store.replace(tx);
      }
      if (mounted) Navigator.pop(context, tx);
    } catch (error) {
      if (mounted) NexoraToast.show(context, 'Gagal menyimpan transaksi: $error', error: true);
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
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (mounted && picked != null) setState(() => _selectedDate = DateUtils.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletProvider);
    final wallets = ref.watch(visibleWalletsProvider);
    final selectedWallet = _selectedWallet(wallets);
    final title = widget.isEditing
        ? (widget.income ? 'Edit Pemasukan' : 'Edit Pengeluaran')
        : (widget.income ? 'Tambah Pemasukan' : 'Tambah Pengeluaran');

    return NexoraScaffold(
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          NexoraInlineHeader(title: title, showBack: true),
          const SizedBox(height: AppSpacing.xl),
          NexoraCurrencyField(
            controller: _amountController,
            label: widget.income ? 'Jumlah masuk' : 'Jumlah keluar',
            semanticColor: widget.income ? NexoraCurrencySemantic.income : NexoraCurrencySemantic.expense,
            helperText: widget.income ? 'Catat pemasukan secara konsisten.' : 'Pantau pengeluaran sebelum budget bocor.',
          ),
          const SizedBox(height: AppSpacing.lg),
          NexoraInput(controller: _titleController, label: 'Nama transaksi', hintText: widget.income ? 'Contoh: Gaji' : 'Contoh: Makan siang'),
          const SizedBox(height: AppSpacing.md),
          NexoraSelect<TransactionCategory>(
            label: 'Kategori',
            valueLabel: _category.labelId,
            options: [
              for (final category in TransactionCategory.values)
                NexoraSelectOption(value: category, label: category.labelId),
            ],
            onSelected: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: AppSpacing.md),
          NexoraSelect<String>(
            label: 'Wallet',
            valueLabel: walletsAsync.isLoading ? 'Memuat wallet...' : selectedWallet?.name ?? 'Pilih wallet',
            enabled: wallets.isNotEmpty,
            options: [
              for (final wallet in wallets)
                NexoraSelectOption(value: wallet.id, label: wallet.name, subtitle: wallet.maskedAccount),
            ],
            onSelected: (value) => setState(() => _walletId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          NexoraSurface(
            onTap: _selectDate,
            semanticLabel: 'Tanggal',
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal', style: AppTypography.caption),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate), style: AppTypography.labelLarge),
                    ],
                  ),
                ),
                const Icon(LucideIcons.calendar, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          NexoraButton(
            label: _saving ? 'Menyimpan...' : widget.isEditing ? 'Simpan Perubahan' : 'Simpan Transaksi',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Transaksi akan memperbarui saldo dan ringkasan keuangan secara otomatis.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  WalletModel? _selectedWallet(List<WalletModel> wallets) {
    final id = _walletId ?? ref.read(primaryWalletProvider)?.id;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }
}
