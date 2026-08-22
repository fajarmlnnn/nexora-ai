import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_model.dart';
import 'add_wallet_sheet.dart';
import 'edit_wallet_sheet.dart';
import 'transfer_wallet_sheet.dart';
import 'wallet_detail_page.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});
  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  bool _visible = true;
  Future<void> _add() => showAddWalletSheet(context, ref);
  Future<void> _transfer() => showTransferWalletSheet(context, ref);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(walletProvider);
    final wallets = ref.watch(visibleWalletsProvider);
    final total = ref.watch(totalWalletBalanceProvider);
    return PremiumScaffold(child: async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryLight)),
      error: (error, _) => Center(child: _ErrorState(message: '$error', onRetry: () => ref.read(walletProvider.notifier).refreshWallets())),
      data: (_) {
        if (wallets.isEmpty) return _EmptyWallet(onAdd: _add);
        return RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: AppColors.card,
          onRefresh: () => ref.read(walletProvider.notifier).refreshWallets(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 24),
            children: [
              Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Wallet', style: AppTypography.heading1.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('Satu tempat untuk seluruh asetmu', style: AppTypography.bodySmall)])), _ActionButton(icon: LucideIcons.arrowLeftRight, onTap: _transfer), const SizedBox(width: 8), _ActionButton(icon: LucideIcons.plus, onTap: _add, primary: true)]),
              const SizedBox(height: 18),
              _TotalCard(balance: total, visible: _visible, onToggle: () => setState(() => _visible = !_visible)),
              const SizedBox(height: 14),
              _Distribution(wallets: wallets, total: total),
              const SizedBox(height: 24),
              Row(children: [Expanded(child: Text('Semua Wallet', style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800))), Text('${wallets.length} akun', style: AppTypography.caption)]),
              const SizedBox(height: 10),
              ...wallets.map((wallet) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _WalletTile(wallet: wallet, total: total, onEdit: () => showEditWalletSheet(context, ref, wallet)))),
              _AddWalletButton(onTap: _add),
            ],
          ),
        );
      },
    ));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap, this.primary = false});
  final IconData icon; final VoidCallback onTap; final bool primary;
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, shape: const CircleBorder(), child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Ink(width: 43, height: 43, decoration: BoxDecoration(shape: BoxShape.circle, gradient: primary ? AppGradients.primary : null, color: primary ? null : AppColors.card, border: Border.all(color: AppColors.border)), child: Icon(icon, color: Colors.white, size: 19))));
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.balance, required this.visible, required this.onToggle});
  final double balance; final bool visible; final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: AppRadius.radiusXXL, gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF241647), Color(0xFF151126), Color(0xFF0C101A)]), border: Border.all(color: const Color(0xFFB98AFF).withValues(alpha: .20)), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .18), blurRadius: 30, offset: const Offset(0, 14))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(LucideIcons.walletMinimal, size: 17, color: AppColors.primaryLight), const SizedBox(width: 8), Text('TOTAL ASSETS', style: AppTypography.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800)), const Spacer(), IconButton(onPressed: onToggle, icon: Icon(visible ? LucideIcons.eye : LucideIcons.eyeOff, size: 18))]), const SizedBox(height: 10), FittedBox(alignment: Alignment.centerLeft, child: Text(visible ? rupiah(balance) : 'Rp •••••••', style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.w900))), const SizedBox(height: 6), Text('Gabungan saldo dari seluruh wallet aktif', style: AppTypography.caption), const SizedBox(height: 15), const Divider(color: Color(0x182FFFFFF)), const SizedBox(height: 5), Row(children: [const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.success), const SizedBox(width: 6), Text('Portfolio synced', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)), const Spacer(), const Icon(LucideIcons.sparkles, size: 13, color: AppColors.primaryLight), const SizedBox(width: 5), Text('Nexora', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800))])])));
}

class _Distribution extends StatelessWidget {
  const _Distribution({required this.wallets, required this.total});
  final List<WalletModel> wallets; final double total;
  @override
  Widget build(BuildContext context) {
    double amount(WalletType type) => wallets.where((w) => w.type == type).fold(0.0, (sum, w) => sum + w.balance);
    final entries = [(label: 'Bank', amount: amount(WalletType.bank), color: const Color(0xFFA66BFF)), (label: 'E-Wallet', amount: amount(WalletType.ewallet), color: const Color(0xFF22D3EE)), (label: 'Cash', amount: amount(WalletType.cash), color: const Color(0xFFFBBF24))];
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .58), borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.border.withValues(alpha: .4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(LucideIcons.chartNoAxesCombined, size: 16, color: AppColors.primaryLight), const SizedBox(width: 7), Text('Asset distribution', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)), const Spacer(), Text('LIVE', style: AppTypography.overline.copyWith(color: AppColors.success))]), const SizedBox(height: 12), Row(children: [for (final entry in entries) Expanded(child: Padding(padding: const EdgeInsets.only(right: 7), child: _DistributionItem(label: entry.label, amount: entry.amount, total: total, color: entry.color)))]) ]));
  }
}

class _DistributionItem extends StatelessWidget {
  const _DistributionItem({required this.label, required this.amount, required this.total, required this.color});
  final String label; final double amount; final double total; final Color color;
  @override
  Widget build(BuildContext context) { final ratio = total <= 0 ? 0.0 : (amount / total).clamp(0.0, 1.0).toDouble(); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.overline), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: ratio, minHeight: 5, backgroundColor: Colors.white.withValues(alpha: .06), valueColor: AlwaysStoppedAnimation(color))), const SizedBox(height: 4), Text('${(ratio * 100).round()}%', style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w800))]); }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet, required this.total, required this.onEdit});
  final WalletModel wallet; final double total; final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (wallet.balance / total).clamp(0.0, 1.0).toDouble();
    return Material(color: AppColors.card.withValues(alpha: .72), borderRadius: AppRadius.radiusXL, child: InkWell(borderRadius: AppRadius.radiusXL, onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WalletDetailPage(walletId: wallet.id))), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .10), borderRadius: AppRadius.radiusLG), child: Icon(wallet.icon, color: AppColors.primaryLight)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(wallet.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800))), if (wallet.isPrimary) ...[const SizedBox(width: 6), const Text('PRIMARY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primaryLight))]]), const SizedBox(height: 3), Text('${wallet.bankName} • ${wallet.maskedAccount}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption), const SizedBox(height: 7), LinearProgressIndicator(value: ratio, minHeight: 3, backgroundColor: Colors.white.withValues(alpha: .05), valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight))])), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(rupiah(wallet.balance), style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w900)), IconButton(tooltip: 'Edit wallet', onPressed: onEdit, icon: const Icon(LucideIcons.ellipsis, size: 18), visualDensity: VisualDensity.compact)])]))));
  }
}

class _AddWalletButton extends StatelessWidget {
  const _AddWalletButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton.icon(onPressed: onTap, icon: const Icon(LucideIcons.plus), label: const Text('Tambah Wallet'), style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL)));
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: AppSpacing.screen, child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.walletCards, size: 52, color: AppColors.primaryLight), const SizedBox(height: 14), Text('Belum ada wallet', style: AppTypography.heading2), const SizedBox(height: 6), Text('Tambahkan wallet pertama untuk mulai mengelola asetmu.', textAlign: TextAlign.center, style: AppTypography.bodySmall), const SizedBox(height: 18), FilledButton.icon(onPressed: onAdd, icon: const Icon(LucideIcons.plus), label: const Text('Tambah Wallet'))])));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message; final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: AppSpacing.screen, child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.triangleAlert, size: 42, color: AppColors.danger), const SizedBox(height: 12), Text('Wallet gagal dimuat', style: AppTypography.heading3), const SizedBox(height: 6), Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTypography.bodySmall), const SizedBox(height: 16), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(LucideIcons.rotateCcw), label: const Text('Coba lagi'))])));
}
