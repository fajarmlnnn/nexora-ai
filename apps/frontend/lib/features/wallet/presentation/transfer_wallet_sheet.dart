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

Future<void> showTransferWalletSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (_) => const _TransferWalletSheet(),
  );
}

class _TransferWalletSheet extends ConsumerStatefulWidget {
  const _TransferWalletSheet();

  @override
  ConsumerState<_TransferWalletSheet> createState() => _TransferWalletSheetState();
}

class _TransferWalletSheetState extends ConsumerState<_TransferWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _sourceId;
  String? _destinationId;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<WalletModel> wallets) async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final sourceId = _sourceId;
    final destinationId = _destinationId;
    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '').trim());

    if (sourceId == null || destinationId == null) {
      _showError('Pilih wallet sumber dan tujuan.');
      return;
    }
    if (sourceId == destinationId) {
      _showError('Wallet sumber dan tujuan harus berbeda.');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Nominal transfer harus lebih besar dari nol.');
      return;
    }

    WalletModel? source;
    WalletModel? destination;
    for (final wallet in wallets) {
      if (wallet.id == sourceId) source = wallet;
      if (wallet.id == destinationId) destination = wallet;
    }

    if (source == null || destination == null) {
      _showError('Wallet sumber atau tujuan tidak tersedia.');
      return;
    }
    if (source!.isHidden || destination!.isHidden) {
      _showError('Wallet tersembunyi tidak dapat digunakan untuk transfer.');
      return;
    }
    if (source!.balance < amount) {
      _showError('Saldo ${source!.name} tidak mencukupi.');
      return;
    }

    setState(() => _saving = true);
    final success = await ref.read(walletProvider.notifier).transferBetweenWallets(
      sourceWalletId: sourceId,
      destinationWalletId: destinationId,
      amount: amount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!success) {
      _showError('Transfer gagal disimpan. Coba lagi.');
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${rupiah(amount)} berhasil dipindahkan ke ${destination!.name}.'), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(visibleWalletsProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    if (wallets.length < 2) {
      return Padding(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 24 + bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.arrowLeftRight, size: 36, color: AppColors.primaryLight),
          const SizedBox(height: 12),
          Text('Transfer Antar Wallet', style: AppTypography.heading2),
          const SizedBox(height: 6),
          Text('Minimal dua wallet aktif diperlukan untuk melakukan transfer.', textAlign: TextAlign.center, style: AppTypography.bodySmall),
          const SizedBox(height: 18),
        ]),
      );
    }

    _sourceId ??= wallets.first.id;
    _destinationId ??= wallets.firstWhere((wallet) => wallet.id != _sourceId, orElse: () => wallets.last).id;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.radiusPill))),
            const SizedBox(height: 18),
            Text('Transfer Antar Wallet', style: AppTypography.heading2),
            const SizedBox(height: 3),
            Text('Memindahkan dana tanpa mengubah total aset atau cashflow.', style: AppTypography.bodySmall),
            const SizedBox(height: 18),
            _walletDropdown(label: 'Dari wallet', value: _sourceId, wallets: wallets, onChanged: _saving ? null : (value) => setState(() => _sourceId = value)),
            const SizedBox(height: 12),
            Center(child: Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .12), shape: BoxShape.circle), child: const Icon(LucideIcons.arrowDown, size: 17, color: AppColors.primaryLight))),
            const SizedBox(height: 12),
            _walletDropdown(label: 'Ke wallet', value: _destinationId, wallets: wallets, onChanged: _saving ? null : (value) => setState(() => _destinationId = value)),
            const SizedBox(height: 12),
            TextFormField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: false), style: AppTypography.bodySmall.copyWith(color: Colors.white), validator: (value) { final amount = double.tryParse((value ?? '').replaceAll('.', '').replaceAll(',', '').trim()); return amount == null || amount <= 0 ? 'Masukkan nominal transfer yang valid.' : null; }, decoration: _decoration('Nominal transfer', LucideIcons.banknote, hint: '0')),
            const SizedBox(height: 12),
            TextFormField(controller: _noteController, maxLines: 2, style: AppTypography.bodySmall.copyWith(color: Colors.white), decoration: _decoration('Catatan (opsional)', LucideIcons.notebookPen, hint: 'Contoh: pindah dana operasional')),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: AppRadius.radiusLG), child: ElevatedButton.icon(onPressed: _saving ? null : () => _submit(wallets), icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.arrowLeftRight), label: Text(_saving ? 'Memproses...' : 'Transfer Sekarang'), style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, disabledForegroundColor: Colors.white70, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG))))),
            SizedBox(height: AppSpacing.bottomNav(context)),
          ]),
        ),
      ),
    );
  }

  Widget _walletDropdown({required String label, required String? value, required List<WalletModel> wallets, required ValueChanged<String?>? onChanged}) => DropdownButtonFormField<String>(initialValue: value, decoration: _decoration(label, LucideIcons.walletMinimal), dropdownColor: AppColors.card, items: wallets.map((wallet) => DropdownMenuItem(value: wallet.id, child: Text('${wallet.name} • ${rupiah(wallet.balance)}', overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged);

  InputDecoration _decoration(String label, IconData icon, {String? hint}) => InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 19), filled: true, fillColor: AppColors.card, border: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))), enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: BorderSide(color: AppColors.border.withValues(alpha: .5))), focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusLG, borderSide: const BorderSide(color: AppColors.primaryLight)));
}
