import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_model.dart';
import 'add_wallet_sheet.dart';
import 'edit_wallet_sheet.dart';
import 'wallet_detail_page.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  bool _isBalanceVisible = true;

  Future<void> _addWallet() => showAddWalletSheet(context, ref);

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletProvider);
    final wallets = ref.watch(visibleWalletsProvider);
    final total = ref.watch(totalWalletBalanceProvider);

    return PremiumScaffold(
      child: walletsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight),
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(walletProvider.notifier).refreshWallets(),
        ),
        data: (_) {
          if (wallets.isEmpty) return _EmptyWallet(onAdd: _addWallet);

          return RefreshIndicator(
            color: AppColors.primaryLight,
            backgroundColor: AppColors.card,
            onRefresh: () => ref.read(walletProvider.notifier).refreshWallets(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 18),
              children: [
                _Header(onAdd: _addWallet),
                const SizedBox(height: 12),
                _TotalCard(balance: total, visible: _isBalanceVisible, onToggle: () => setState(() => _isBalanceVisible = !_isBalanceVisible)),
                const SizedBox(height: 18),
                Text('Semua Wallet', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final wallet in wallets) ...[
                  _WalletTile(
                    wallet: wallet,
                    totalBalance: total,
                    onEdit: () => showEditWalletSheet(context, ref, wallet),
                  ),
                  const SizedBox(height: 7),
                ],
                const SizedBox(height: 8),
                _AddWalletInline(onTap: _addWallet),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Wallet', style: AppTypography.heading1),
      Text('Kelola semua asetmu', style: AppTypography.bodySmall),
    ])),
    Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onAdd,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle, border: Border.all(color: AppColors.border.withValues(alpha: .45))),
          child: const Center(child: Icon(LucideIcons.plus, color: AppColors.primaryLight, size: 20)),
        ),
      ),
    ),
  ]);
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.balance, required this.visible, required this.onToggle});
  final double balance;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
    borderRadius: AppRadius.radiusXXL,
    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF171525), Color(0xFF12121C), Color(0xFF0D0E15)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Total Aset', style: AppTypography.bodySmall),
        const SizedBox(width: 6),
        GestureDetector(onTap: onToggle, child: Icon(visible ? LucideIcons.eye : LucideIcons.eyeOff, size: 17, color: AppColors.textSecondary)),
        const Spacer(),
        Text('100%', style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 5),
      FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(visible ? rupiah(balance) : 'Rp •••••••', style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.w800, color: Colors.white))),
      const SizedBox(height: 4),
      Text('Gabungan saldo wallet yang terlihat', style: AppTypography.caption),
    ]),
  );
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet, required this.totalBalance, required this.onEdit});
  final WalletModel wallet;
  final double totalBalance;
  final VoidCallback onEdit;

  double get percentage => totalBalance <= 0 || wallet.balance <= 0 ? 0 : (wallet.balance / totalBalance) * 100;

  Color get accentColor {
    switch (wallet.type) {
      case WalletType.bank: return AppColors.primary;
      case WalletType.ewallet: return AppColors.info;
      case WalletType.cash: return AppColors.warning;
      case WalletType.investment: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: AppRadius.radiusXL,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WalletDetailPage(walletId: wallet.id))),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: AppRadius.radiusXL,
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: accentColor.withValues(alpha: .12), borderRadius: AppRadius.radiusLG), child: Icon(wallet.icon, color: accentColor, size: 21)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(wallet.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))),
              if (wallet.isPrimary) ...[const SizedBox(width: 5), const Text('PRIMARY', style: TextStyle(color: AppColors.primaryLight, fontSize: 8, fontWeight: FontWeight.w800))],
            ]),
            const SizedBox(height: 2),
            Text('${wallet.bankName} • ${wallet.maskedAccount}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
          ])),
          const SizedBox(width: 5),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(rupiah(wallet.balance), style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('${percentage.toStringAsFixed(1)}%', style: AppTypography.caption.copyWith(color: accentColor, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(width: 2),
          IconButton(
            tooltip: 'Edit wallet',
            onPressed: onEdit,
            icon: const Icon(LucideIcons.pencil, size: 17, color: AppColors.textSecondary),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    ),
  );
}

class _AddWalletInline extends StatelessWidget {
  const _AddWalletInline({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: AppRadius.radiusLG,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusLG,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: AppRadius.radiusLG, boxShadow: AppShadows.button),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(LucideIcons.plus, color: Colors.white, size: 18),
          const SizedBox(width: 7),
          Text('Tambah Wallet', style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
      ),
    ),
  );
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 20),
    children: [
      _Header(onAdd: onAdd),
      const SizedBox(height: 120),
      Icon(LucideIcons.walletMinimal, size: 58, color: AppColors.primaryLight.withValues(alpha: .8)),
      const SizedBox(height: 18),
      Text('Belum Ada Wallet', textAlign: TextAlign.center, style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Text('Tambahkan rekening bank, e-wallet, uang tunai, atau investasi untuk mulai mengelola asetmu.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(height: 1.5))),
      const SizedBox(height: 20),
      Center(child: _AddWalletInline(onTap: onAdd)),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(LucideIcons.triangleAlert, color: AppColors.warning, size: 36),
      const SizedBox(height: 10),
      Text('Wallet gagal dimuat', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(message, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
      const SizedBox(height: 14),
      TextButton.icon(onPressed: onRetry, icon: const Icon(LucideIcons.refreshCw), label: const Text('Coba lagi')),
    ]),
  ));
}
