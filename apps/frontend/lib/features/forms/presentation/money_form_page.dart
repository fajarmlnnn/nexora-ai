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
        date: DateTime.now(),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.income ? AppColors.success : AppColors.danger;

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
            label: 'Tanggal',
            value: 'Hari ini',
            onTap: () {},
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
  const _SelectionCard({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

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
