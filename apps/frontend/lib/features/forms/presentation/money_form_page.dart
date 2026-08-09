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
  const MoneyFormPage({super.key, required this.income});

  final bool income;

  @override
  ConsumerState<MoneyFormPage> createState() => _MoneyFormPageState();
}

class _MoneyFormPageState extends ConsumerState<MoneyFormPage> {
  late final TextEditingController _amountController;
  final TextEditingController _titleController = TextEditingController();
  TransactionCategory _category = TransactionCategory.other;
  String? _walletId;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _titleController.text = widget.income ? 'Pemasukan' : 'Pengeluaran';
    _category = widget.income
        ? TransactionCategory.salary
        : TransactionCategory.food;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (amount == null || amount <= 0) {
      _showError('Masukkan jumlah yang valid.');
      return;
    }

    final wallets = ref.read(visibleWalletsProvider);
    final selectedWalletId = _walletId ?? ref.read(primaryWalletProvider)?.id;
    if (selectedWalletId == null || wallets.isEmpty) {
      _showError('Pilih wallet terlebih dahulu.');
      return;
    }

    setState(() => _saving = true);
    try {
      final transaction = TransactionModel(
        id: 'tx-${DateTime.now().microsecondsSinceEpoch}',
        title: _titleController.text.trim().isEmpty
            ? (widget.income ? 'Pemasukan' : 'Pengeluaran')
            : _titleController.text.trim(),
        amount: amount,
        type: widget.income ? TransactionType.income : TransactionType.expense,
        category: _category,
        date: DateUtils.dateOnly(_selectedDate),
        walletId: selectedWalletId,
      );

      await ref.read(financialTransactionStoreProvider.notifier).add(transaction);
      if (!mounted) return;
      Navigator.pop(context, transaction);
    } catch (error) {
      if (mounted) _showError('Gagal menyimpan transaksi: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = DateTime(2020, 1, 1);
    final lastDate = DateTime(today.year + 10, 12, 31);
    final current = DateUtils.dateOnly(_selectedDate);
    final initialDate = current.isBefore(firstDate)
        ? firstDate
        : current.isAfter(lastDate)
            ? lastDate
            : current;

    // Jangan memaksa locale id_ID pada DatePicker. Jika MaterialLocalizations
    // aplikasi belum mendaftarkan locale tersebut, showDatePicker dapat gagal
    // setelah barrier ditampilkan sehingga layar terlihat abu-abu.
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: widget.income
          ? 'Pilih tanggal pemasukan'
          : 'Pilih tanggal pengeluaran',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      useRootNavigator: true,
      builder: (dialogContext, child) {
        if (child == null) return const SizedBox.shrink();

        final baseTheme = Theme.of(dialogContext);
        final scheme = baseTheme.colorScheme;

        return Theme(
          data: baseTheme.copyWith(
            brightness: Brightness.dark,
            colorScheme: scheme.copyWith(
              brightness: Brightness.dark,
              primary: AppColors.primaryLight,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: Colors.white,
            ),
            dialogTheme: baseTheme.dialogTheme.copyWith(
              backgroundColor: AppColors.card,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: child,
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() => _selectedDate = DateUtils.dateOnly(picked));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.income ? AppColors.success : AppColors.danger;
    final walletsAsync = ref.watch(walletProvider);
    final wallets = ref.watch(visibleWalletsProvider);
    final selectedWallet = _selectedWallet(wallets);

    return PremiumScaffold(
      bottomPadding: false,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BackButton(
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Icon(
            widget.income
                ? LucideIcons.arrowUpCircle
                : LucideIcons.arrowDownCircle,
            color: accent,
            size: 92,
          ),
          const SizedBox(height: 10),
          Text(
            widget.income ? 'Tambah Pemasukan' : 'Tambah Pengeluaran',
            textAlign: TextAlign.center,
            style: AppTypography.heading1,
          ),
          Text(
            widget.income
                ? 'Catat pemasukan agar cashflow selalu akurat.'
                : 'Catat pengeluaran sebelum budget bocor.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          AppSpacing.gapLG,
          _InputCard(
            label: 'Jumlah',
            controller: _amountController,
            hint: 'Contoh: 150000',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          _InputCard(
            label: 'Nama transaksi',
            controller: _titleController,
            hint: 'Contoh: Gaji / Makan siang',
          ),
          _SelectionCard(
            label: 'Kategori',
            value: _categoryLabel(_category),
            onTap: _selectCategory,
          ),
          _SelectionCard(
            label: 'Wallet',
            value: walletsAsync.isLoading
                ? 'Memuat wallet...'
                : selectedWallet?.name ?? 'Pilih wallet',
            onTap: wallets.isEmpty ? null : _selectWallet,
          ),
          _SelectionCard(
            label: 'Tanggal',
            value: DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate),
            onTap: _selectDate,
          ),
          AppSpacing.gapMD,
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save),
            label: Text(
              _saving
                  ? 'Menyimpan...'
                  : widget.income
                      ? 'Simpan Pemasukan'
                      : 'Simpan Pengeluaran',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
            ),
          ),
        ],
      ),
    );
  }

  WalletModel? _selectedWallet(List<WalletModel> wallets) {
    final id = _walletId ?? ref.read(primaryWalletProvider)?.id;
    if (id == null) return null;

    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  Future<void> _selectWallet() async {
    final wallets = ref.read(visibleWalletsProvider);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            for (final wallet in wallets)
              ListTile(
                leading: Icon(wallet.icon, color: wallet.color),
                title: Text(wallet.name),
                subtitle: Text(wallet.maskedAccount),
                trailing: wallet.id == (_walletId ?? ref.read(primaryWalletProvider)?.id)
                    ? const Icon(LucideIcons.check, color: AppColors.primaryLight)
                    : null,
                onTap: () => Navigator.pop(context, wallet.id),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _walletId = selected);
  }

  Future<void> _selectCategory() async {
    final selected = await showModalBottomSheet<TransactionCategory>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            for (final category in TransactionCategory.values)
              ListTile(
                title: Text(_categoryLabel(category)),
                trailing: category == _category
                    ? const Icon(LucideIcons.check, color: AppColors.primaryLight)
                    : null,
                onTap: () => Navigator.pop(context, category),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _category = selected);
  }

  String _categoryLabel(TransactionCategory category) {
    return switch (category) {
      TransactionCategory.food => 'Makan & Minum',
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
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PremiumCard(
        borderRadius: AppRadius.radiusXL,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          style: AppTypography.labelLarge,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.radiusXL,
          onTap: onTap,
          child: PremiumCard(
            borderRadius: AppRadius.radiusXL,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTypography.caption),
                      const SizedBox(height: 4),
                      Text(value, style: AppTypography.labelLarge),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronDown, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
