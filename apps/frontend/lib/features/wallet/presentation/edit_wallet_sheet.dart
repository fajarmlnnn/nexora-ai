import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_model.dart';

Future<void> showEditWalletSheet(
  BuildContext context,
  WidgetRef ref,
  WalletModel wallet,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (_) => _EditWalletSheet(wallet: wallet),
  );
}

class _EditWalletSheet extends ConsumerStatefulWidget {
  const _EditWalletSheet({required this.wallet});
  final WalletModel wallet;

  @override
  ConsumerState<_EditWalletSheet> createState() => _EditWalletSheetState();
}

class _EditWalletSheetState extends ConsumerState<_EditWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _providerController;
  late final TextEditingController _accountController;
  late final TextEditingController _minimumController;
  late WalletType _type;
  late bool _isPrimary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet.name);
    _providerController = TextEditingController(text: widget.wallet.bankName);
    _accountController = TextEditingController(text: widget.wallet.accountNumber);
    _minimumController = TextEditingController(
      text: widget.wallet.minimumBalance == 0
          ? '0'
          : widget.wallet.minimumBalance.toStringAsFixed(0),
    );
    _type = widget.wallet.type;
    _isPrimary = widget.wallet.isPrimary;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _accountController.dispose();
    _minimumController.dispose();
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

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final minimum = double.tryParse(
      _minimumController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (minimum == null || minimum < 0) {
      _showError('Saldo minimum tidak valid.');
      return;
    }

    setState(() => _saving = true);
    final updated = widget.wallet.copyWith(
      name: _nameController.text.trim(),
      bankName: _providerController.text.trim(),
      accountNumber: _accountController.text.trim(),
      type: _type,
      minimumBalance: minimum,
      isPrimary: _isPrimary,
    );

    final success = await ref.read(walletProvider.notifier).updateWallet(updated);
    if (!mounted) return;
    if (!success) {
      setState(() => _saving = false);
      _showError('Wallet gagal diperbarui.');
      return;
    }

    if (_isPrimary) {
      await ref.read(walletProvider.notifier).setPrimaryWallet(widget.wallet.id);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wallet berhasil diperbarui.'),
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
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.radiusPill))),
              const SizedBox(height: 18),
              Text('Edit Wallet', style: AppTypography.heading2),
              const SizedBox(height: 3),
              Text('Perbarui identitas dan batas keamanan wallet.', style: AppTypography.bodySmall),
              const SizedBox(height: 18),
              _Field(controller: _nameController, label: 'Nama wallet', icon: LucideIcons.walletMinimal, validator: (v) => v == null || v.trim().isEmpty ? 'Nama wallet wajib diisi.' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<WalletType>(
                initialValue: _type,
                decoration: _decoration('Tipe wallet', LucideIcons.layers3),
                dropdownColor: AppColors.card,
                items: WalletType.values.map((type) => DropdownMenuItem(value: type, child: Text(_typeLabel(type)))).toList(),
                onChanged: _saving ? null : (value) => setState(() => _type = value ?? WalletType.bank),
              ),
              const SizedBox(height: 12),
              _Field(controller: _providerController, label: 'Bank / platform', icon: LucideIcons.building2),
              const SizedBox(height: 12),
              _Field(controller: _accountController, label: 'Nomor akun', icon: LucideIcons.hash),
              const SizedBox(height: 12),
              _Field(
                controller: _minimumController,
                label: 'Saldo minimum',
                icon: LucideIcons.shieldCheck,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                validator: (v) {
                  final parsed = double.tryParse((v ?? '').replaceAll('.', '').replaceAll(',', ''));
                  return parsed == null || parsed < 0 ? 'Masukkan saldo minimum yang valid.' : null;
                },
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Jadikan wallet utama', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('Wallet ini diprioritaskan di ringkasan.', style: AppTypography.caption),
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
                    icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.save),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, disabledForegroundColor: Colors.white70, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG)),
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

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 19),
    filled: true,
    fillColor: AppColors.card,
    border: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
    enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
    focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: const BorderSide(color: AppColors.primaryLight)),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, required this.icon, this.validator, this.keyboardType});
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    style: AppTypography.bodySmall.copyWith(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: const BorderSide(color: AppColors.primaryLight)),
    ),
  );
}
