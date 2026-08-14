import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_model.dart';

Future<void> showAddWalletSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (_) => const _AddWalletSheet(),
  );
}

class _AddWalletSheet extends ConsumerStatefulWidget {
  const _AddWalletSheet();

  @override
  ConsumerState<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends ConsumerState<_AddWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _providerController = TextEditingController();
  final _accountController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');

  WalletType _type = WalletType.bank;
  bool _isPrimary = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _accountController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String _typeLabel(WalletType type) {
    switch (type) {
      case WalletType.bank:
        return 'Bank';
      case WalletType.ewallet:
        return 'E-Wallet';
      case WalletType.cash:
        return 'Uang Tunai';
      case WalletType.investment:
        return 'Investasi';
    }
  }

  String _defaultProvider(WalletType type) {
    switch (type) {
      case WalletType.bank:
        return 'Nama bank';
      case WalletType.ewallet:
        return 'Nama e-wallet';
      case WalletType.cash:
        return 'Tunai';
      case WalletType.investment:
        return 'Platform investasi';
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final balance = double.tryParse(
      _balanceController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (balance == null || balance < 0) {
      _showError('Saldo awal tidak valid.');
      return;
    }

    setState(() => _saving = true);

    final wallet = WalletModel(
      // The Supabase repository replaces this local ID with a database UUID
      // when it is not already a UUID. The returned WalletModel is canonical.
      id: 'wallet_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      bankName: _providerController.text.trim().isEmpty
          ? _defaultProvider(_type)
          : _providerController.text.trim(),
      accountNumber: _accountController.text.trim().isEmpty
          ? _type.name.toUpperCase()
          : _accountController.text.trim(),
      balance: 0,
      type: _type,
      color: AppColors.primary,
      isPrimary: _isPrimary,
    );

    final created = await ref.read(walletProvider.notifier).addWallet(wallet);
    if (!mounted) return;

    if (created == null) {
      setState(() => _saving = false);
      _showError('Wallet gagal disimpan. Coba lagi.');
      return;
    }

    try {
      if (balance > 0) {
        await ref.read(financialTransactionStoreProvider.notifier).add(
          TransactionModel(
            id: 'opening-${DateTime.now().microsecondsSinceEpoch}',
            title: 'Saldo awal ${created.name}',
            amount: balance,
            type: TransactionType.income,
            category: TransactionCategory.other,
            date: DateTime.now(),
            walletId: created.id,
          ),
        );
      }

      if (_isPrimary) {
        final primarySet = await ref
            .read(walletProvider.notifier)
            .setPrimaryWallet(created.id);
        if (!primarySet) {
          throw StateError('Wallet berhasil dibuat, tetapi gagal dijadikan wallet utama.');
        }
      }
    } catch (error) {
      // Avoid leaving an orphan wallet when the opening transaction fails.
      await ref.read(walletProvider.notifier).deleteWallet(created.id);
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Gagal menyimpan saldo awal: $error');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${created.name} berhasil ditambahkan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.radiusPill,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Tambah Wallet', style: AppTypography.heading2),
              const SizedBox(height: 3),
              Text('Tambahkan aset agar saldo dan transaksi bisa dilacak dengan benar.', style: AppTypography.bodySmall),
              const SizedBox(height: 18),
              _Field(
                controller: _nameController,
                label: 'Nama wallet',
                hint: 'Contoh: BCA Utama',
                icon: LucideIcons.walletMinimal,
                validator: (value) => value == null || value.trim().isEmpty ? 'Nama wallet wajib diisi.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WalletType>(
                initialValue: _type,
                decoration: _decoration('Tipe wallet', LucideIcons.layers3),
                dropdownColor: AppColors.card,
                items: WalletType.values
                    .map((type) => DropdownMenuItem(value: type, child: Text(_typeLabel(type))))
                    .toList(),
                onChanged: _saving ? null : (value) => setState(() => _type = value ?? WalletType.bank),
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _providerController,
                label: _type == WalletType.cash ? 'Sumber' : 'Bank / platform',
                hint: _defaultProvider(_type),
                icon: LucideIcons.building2,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _accountController,
                label: 'Nomor akun (opsional)',
                hint: 'Boleh dikosongkan',
                icon: LucideIcons.hash,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _balanceController,
                label: 'Saldo awal',
                hint: '0',
                icon: LucideIcons.walletCards,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').replaceAll('.', '').replaceAll(',', ''));
                  return parsed == null || parsed < 0 ? 'Masukkan saldo yang valid.' : null;
                },
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Jadikan wallet utama', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('Wallet ini akan diprioritaskan di ringkasan.', style: AppTypography.caption),
                value: _isPrimary,
                activeTrackColor: AppColors.primary,
                onChanged: _saving ? null : (value) => setState(() => _isPrimary = value),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: AppRadius.radiusLG),
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.plus),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Wallet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.bottomNav(context)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: const BorderSide(color: AppColors.primaryLight)),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.hint, required this.icon, this.validator, this.keyboardType});

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: AppTypography.bodySmall.copyWith(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: const BorderSide(color: AppColors.primaryLight)),
      ),
    );
  }
}
