import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../../wallet/models/wallet_model.dart';

class TransferPage extends ConsumerStatefulWidget {
  const TransferPage({super.key});

  @override
  ConsumerState<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends ConsumerState<TransferPage> {
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

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amount == null || amount <= 0) {
      _showError('Masukkan nominal transfer yang valid.');
      return;
    }

    final wallets = ref.read(visibleWalletsProvider);
    final sourceId = _sourceId ?? ref.read(primaryWalletProvider)?.id;
    final destinationId = _destinationId ?? _firstDestination(wallets, sourceId);

    if (sourceId == null || destinationId == null) {
      _showError('Pilih wallet sumber dan tujuan.');
      return;
    }
    if (sourceId == destinationId) {
      _showError('Wallet sumber dan tujuan harus berbeda.');
      return;
    }

    final source = _findWallet(wallets, sourceId);
    if (source == null) {
      _showError('Wallet sumber tidak ditemukan.');
      return;
    }
    if (amount > source.balance) {
      _showError('Saldo ${source.name} tidak cukup untuk transfer ini.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(financialTransactionStoreProvider.notifier).transfer(
            sourceWalletId: sourceId,
            destinationWalletId: destinationId,
            amount: amount,
            note: _noteController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer berhasil disimpan.')));
      context.pop();
    } catch (error) {
      if (mounted) _showError(error.toString().replaceFirst('ArgumentError: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(visibleWalletsProvider);
    final source = _findWallet(wallets, _sourceId ?? ref.read(primaryWalletProvider)?.id);
    final destination = _findWallet(wallets, _destinationId ?? _firstDestination(wallets, source?.id));

    return PremiumScaffold(
      bottomPadding: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: AppSpacing.screen.copyWith(bottom: 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Kembali',
                onPressed: () => context.pop(),
                icon: const Icon(LucideIcons.arrowLeft),
              ),
              const SizedBox(width: 2),
              Text('Transfer', style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.glassSurface,
                border: Border.all(color: AppColors.brandPrimary.withValues(alpha: .28)),
                boxShadow: [BoxShadow(color: AppColors.brandPrimary.withValues(alpha: .16), blurRadius: 34, spreadRadius: 4)],
              ),
              child: const Icon(LucideIcons.arrowLeftRight, color: AppColors.brandPrimaryBright, size: 42),
            ),
          ),
          const SizedBox(height: 16),
          Text('Pindahkan uang antar wallet', textAlign: TextAlign.center, style: AppTypography.heading1.copyWith(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Transfer tidak dihitung sebagai pemasukan atau pengeluaran.', textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _WalletSelection(label: 'Dari wallet', wallet: source, onTap: () => _selectWallet(isSource: true, wallets: wallets)),
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.brandPrimary.withValues(alpha: .10), border: Border.all(color: AppColors.brandPrimary.withValues(alpha: .20))),
              child: const Icon(LucideIcons.arrowDown, size: 18, color: AppColors.brandPrimaryBright),
            ),
          ),
          const SizedBox(height: 8),
          _WalletSelection(label: 'Ke wallet', wallet: destination, onTap: () => _selectWallet(isSource: false, wallets: wallets)),
          const SizedBox(height: 14),
          _InputCard(label: 'Nominal transfer', controller: _amountController, hint: 'Contoh: 500000', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          _InputCard(label: 'Catatan (opsional)', controller: _noteController, hint: 'Contoh: Isi saldo GoPay'),
          if (source != null && destination != null) ...[
            const SizedBox(height: 2),
            PremiumCard(
              borderRadius: AppRadius.radiusXL,
              padding: const EdgeInsets.all(14),
              gradient: const LinearGradient(colors: [Color(0x141A123A), Color(0x0AFFFFFF)]),
              child: Row(
                children: [
                  Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.brandPrimary.withValues(alpha: .10)), child: const Icon(LucideIcons.info, size: 17, color: AppColors.brandPrimaryBright)),
                  const SizedBox(width: 9),
                  Expanded(child: Text('Total aset tetap sama. ${source.name} berkurang dan ${destination.name} bertambah sesuai nominal transfer.', style: AppTypography.caption.copyWith(height: 1.45))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.aurora,
              borderRadius: AppRadius.radiusXL,
              boxShadow: [BoxShadow(color: AppColors.brandPrimary.withValues(alpha: .28), blurRadius: 28, offset: const Offset(0, 12))],
            ),
            child: FilledButton.icon(
              onPressed: _saving || wallets.length < 2 ? null : _submit,
              icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.arrowLeftRight),
              label: Text(_saving ? 'Memproses...' : 'Konfirmasi Transfer'),
              style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL)),
            ),
          ),
          if (wallets.length < 2)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Tambahkan minimal dua wallet untuk melakukan transfer.', textAlign: TextAlign.center, style: AppTypography.caption.copyWith(color: AppColors.warning)),
            ),
        ],
      ),
    );
  }

  Future<void> _selectWallet({required bool isSource, required List<WalletModel> wallets}) async {
    final current = isSource ? _sourceId : _destinationId;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .68),
      showDragHandle: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E0B24), Color(0xFF08071A)]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 12), child: Text(isSource ? 'Pilih wallet sumber' : 'Pilih wallet tujuan', style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800))),
              for (final wallet in wallets)
                ListTile(
                  enabled: !(isSource && wallet.id == _destinationId) && !(!isSource && wallet.id == _sourceId),
                  leading: Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.brandPrimary.withValues(alpha: .10)), child: Icon(wallet.icon, color: AppColors.brandPrimaryBright, size: 19)),
                  title: Text(wallet.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                  subtitle: Text('${wallet.maskedAccount} • ${rupiah(wallet.balance)}'),
                  trailing: wallet.id == current ? const Icon(LucideIcons.check, color: AppColors.brandPrimaryBright) : null,
                  onTap: () => Navigator.pop(sheetContext, wallet.id),
                ),
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;
    setState(() {
      if (isSource) {
        _sourceId = selected;
      } else {
        _destinationId = selected;
      }
    });
  }

  WalletModel? _findWallet(List<WalletModel> wallets, String? id) {
    if (id == null) return null;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  String? _firstDestination(List<WalletModel> wallets, String? sourceId) {
    for (final wallet in wallets) {
      if (wallet.id != sourceId) return wallet.id;
    }
    return null;
  }
}

class _WalletSelection extends StatelessWidget {
  const _WalletSelection({required this.label, required this.wallet, required this.onTap});

  final String label;
  final WalletModel? wallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.radiusXL,
          onTap: onTap,
          child: PremiumCard(
            borderRadius: AppRadius.radiusXL,
            padding: const EdgeInsets.all(15),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x181B1730), Color(0x0DFFFFFF)]),
            child: Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.glassSurface, border: Border.all(color: AppColors.brandPrimary.withValues(alpha: .18))), child: Icon(wallet?.icon ?? LucideIcons.wallet, color: AppColors.brandPrimaryBright, size: 20)),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: AppTypography.caption),
                    const SizedBox(height: 3),
                    Text(wallet?.name ?? 'Pilih wallet', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                    if (wallet != null) Text('${wallet!.maskedAccount} • ${rupiah(wallet!.balance)}', style: AppTypography.caption),
                  ]),
                ),
                const Icon(LucideIcons.chevronRight, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      );
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.label, required this.controller, required this.hint, this.keyboardType});

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: PremiumCard(
          borderRadius: AppRadius.radiusXL,
          padding: const EdgeInsets.fromLTRB(16, 7, 16, 4),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x1619162C), Color(0x0AFFFFFF)]),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(labelText: label, hintText: hint, border: InputBorder.none, filled: false),
          ),
        ),
      );
}
