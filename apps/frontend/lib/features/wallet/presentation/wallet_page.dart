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
import 'transfer_wallet_sheet.dart';
import 'wallet_detail_page.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  bool _isBalanceVisible = true;

  Future<void> _addWallet() => showAddWalletSheet(context, ref);
  Future<void> _transferWallet() => showTransferWalletSheet(context, ref);

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletProvider);
    final wallets = ref.watch(visibleWalletsProvider);
    final total = ref.watch(totalWalletBalanceProvider);

    return PremiumScaffold(
      child: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryLight)),
        error: (error, _) => _ErrorState(message: error.toString(), onRetry: () => ref.read(walletProvider.notifier).refreshWallets()),
        data: (_) {
          if (wallets.isEmpty) return _EmptyWallet(onAdd: _addWallet);

          return RefreshIndicator(
            color: AppColors.primaryLight,
            backgroundColor: AppColors.card,
            onRefresh: () => ref.read(walletProvider.notifier).refreshWallets(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 22),
              children: [
                _Header(onAdd: _addWallet, onTransfer: _transferWallet),
                const SizedBox(height: 18),
                _TotalCard(balance: total, visible: _isBalanceVisible, onToggle: () => setState(() => _isBalanceVisible = !_isBalanceVisible)),
                const SizedBox(height: 14),
                _AssetInsight(wallets: wallets, total: total),
                const SizedBox(height: 24),
                Row(children: [Expanded(child: Text('Semua Wallet', style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800))), Text('${wallets.length} akun', style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 10),
                for (final wallet in wallets) ...[
                  _WalletTile(wallet: wallet, totalBalance: total, onEdit: () => showEditWalletSheet(context, ref, wallet)),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 6),
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
  const _Header({required this.onAdd, required this.onTransfer});
  final VoidCallback onAdd;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('Wallet', style: AppTypography.heading1), const SizedBox(width: 6), Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFA66BFF), Color(0xFF22D3EE)])))]),
      const SizedBox(height: 3),
      Text('Satu tempat untuk seluruh asetmu', style: AppTypography.bodySmall),
    ])),
    _HeaderAction(icon: LucideIcons.arrowLeftRight, onTap: onTransfer),
    const SizedBox(width: 8),
    _HeaderAction(icon: LucideIcons.plus, onTap: onAdd, primary: true),
  ]);
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap, this.primary = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, shape: const CircleBorder(), child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Ink(width: 43, height: 43, decoration: BoxDecoration(shape: BoxShape.circle, gradient: primary ? AppGradients.primary : null, color: primary ? null : AppColors.card.withValues(alpha: .72), border: Border.all(color: primary ? Colors.white.withValues(alpha: .16) : AppColors.border.withValues(alpha: .45)), boxShadow: primary ? [BoxShadow(color: AppColors.primary.withValues(alpha: .28), blurRadius: 16, spreadRadius: -4)] : null), child: Center(child: Icon(icon, color: Colors.white, size: 19)))));
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.balance, required this.visible, required this.onToggle});
  final double balance;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
    decoration: BoxDecoration(
      borderRadius: AppRadius.radiusXXL,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF241647), Color(0xFF151126), Color(0xFF0C101A)], stops: [0, .52, 1]),
      border: Border.all(color: const Color(0xFFB98AFF).withValues(alpha: .20)),
      boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: .18), blurRadius: 34, spreadRadius: -12, offset: const Offset(0, 16)), BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 24, spreadRadius: -10, offset: const Offset(0, 10))],
    ),
    child: Stack(children: [
      Positioned(right: -34, top: -45, child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFA66BFF).withValues(alpha: .22), Colors.transparent])))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: AppRadius.radiusMD), child: const Icon(LucideIcons.walletMinimal, size: 15, color: Color(0xFFD8C4FF))), const SizedBox(width: 9), Text('TOTAL ASSETS', style: AppTypography.caption.copyWith(letterSpacing: 1.25, color: const Color(0xFFC8BEDB), fontWeight: FontWeight.w800)), const Spacer(), GestureDetector(onTap: onToggle, child: Icon(visible ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: Colors.white.withValues(alpha: .70)))]),
        const SizedBox(height: 15),
        FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(visible ? rupiah(balance) : 'Rp •••••••', style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -.5))),
        const SizedBox(height: 5),
        Text('Gabungan saldo dari seluruh wallet aktif', style: AppTypography.caption.copyWith(color: const Color(0xFFB5AFC5))),
        const SizedBox(height: 15),
        Container(height: 1, color: Colors.white.withValues(alpha: .08)),
        const SizedBox(height: 11),
        Row(children: [const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF6EE7B7)), const SizedBox(width: 6), Text('Portfolio synced', style: AppTypography.caption.copyWith(color: const Color(0xFFB7B1C5), fontWeight: FontWeight.w700)), const Spacer(), const Icon(LucideIcons.sparkles, size: 13, color: Color(0xFFB98AFF)), const SizedBox(width: 5), Text('Nexora', style: AppTypography.caption.copyWith(color: const Color(0xFFD4C5FF), fontWeight: FontWeight.w800))]),
      ]),
    ]),
  );
}

class _AssetInsight extends StatelessWidget {
  const _AssetInsight({required this.wallets, required this.total});
  final List<WalletModel> wallets;
  final double total;

  @override
  Widget build(BuildContext context) {
    final bank = wallets.where((w) => w.type == WalletType.bank).fold<double>(0, (s, w) => s + w.balance);
    final cash = wallets.where((w) => w.type == WalletType.cash).fold<double>(0, (s, w) => s + w.balance);
    final digital = wallets.where((w) => w.type == WalletType.ewallet).fold<double>(0, (s, w) => s + w.balance);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .52), borderRadius: AppRadius.radiusXL, border: Border.all(color: Colors.white.withValues(alpha: .06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(LucideIcons.chartNoAxesCombined, size: 16, color: Color(0xFFB98AFF)), const SizedBox(width: 7), Text('Asset distribution', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800)), const Spacer(), Text('LIVE', style: AppTypography.overline.copyWith(color: const Color(0xFF6EE7B7), letterSpacing: 1))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _Distribution(label: 'Bank', amount: bank, total: total, color: const Color(0xFFA66BFF))), Expanded(child: _Distribution(label: 'E-Wallet', amount: digital, total: total, color: const Color(0xFF22D3EE))), Expanded(child: _Distribution(label: 'Cash', amount: cash, total: total, color: const Color(0xFFFBBF24)))]),
      ]),
    );
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({required this.label, required this.amount, required this.total, required this.color});
  final String label;
  final double amount;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (amount / total).clamp(0.0, 1.0).toDouble();
    return Padding(padding: const EdgeInsets.only(right: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.overline.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w700)))]), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: ratio, minHeight: 5, backgroundColor: Colors.white.withValues(alpha: .06), valueColor: AlwaysStoppedAnimation(color))), const SizedBox(height: 5), Text('${(ratio * 100).round()}%', style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w800))]));
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet, required this.totalBalance, required this.onEdit});
  final WalletModel wallet;
  final double totalBalance;
  final VoidCallback onEdit;

  double get percentage => totalBalance <= 0 || wallet.balance <= 0 ? 0 : (wallet.balance / totalBalance) * 100;

  Color get accentColor {
    switch (wallet.type) {
      case WalletType.bank: return const Color(0xFFA66BFF);
      case WalletType.ewallet: return const Color(0xFF22D3EE);
      case WalletType.cash: return const Color(0xFFFBBF24);
      case WalletType.investment: return const Color(0xFF6EE7B7);
    }
  }

  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(borderRadius: AppRadius.radiusXL, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WalletDetailPage(walletId: wallet.id))), child: Ink(decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .70), borderRadius: AppRadius.radiusXL, border: Border.all(color: Colors.white.withValues(alpha: .055))), padding: const EdgeInsets.fromLTRB(12, 11, 8, 11), child: Row(children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(color: accentColor.withValues(alpha: .10), borderRadius: AppRadius.radiusLG, border: Border.all(color: accentColor.withValues(alpha: .13))), child: Icon(wallet.icon, color: accentColor, size: 21)),
    const SizedBox(width: 11),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(wallet.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800))), if (wallet.isPrimary) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: accentColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(99)), child: Text('PRIMARY', style: TextStyle(color: accentColor, fontSize: 7, fontWeight: FontWeight.w900))]]), const SizedBox(height: 3), Text('${wallet.bankName} • ${wallet.maskedAccount}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textMuted)), const SizedBox(height: 7), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: (percentage / 100).clamp(0.0, 1.0), minHeight: 3, backgroundColor: Colors.white.withValues(alpha: .05), valueColor: AlwaysStoppedAnimation(accentColor)))])),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(rupiah(wallet.balance), style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('${percentage.toStringAsFixed(1)}%', style: AppTypography.caption.copyWith(color: accentColor, fontWeight: FontWeight.w800)), IconButton(tooltip: 'Edit wallet', onPressed: onEdit, icon: const Icon(LucideIcons.ellipsis, size: 18, color: AppColors.textSecondary), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 28, minHeight: 28))]),
  ]))));
}

class _AddWalletInline extends StatelessWidget {
  const _AddWalletInline({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, borderRadius: AppRadius.radiusXL, child: InkWell(onTap: onTap, borderRadius: AppRadius.radiusXL, child: Ink(height: 52, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: AppRadius.radiusXL, boxShadow: AppShadows.button), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(LucideIcons.plus, color: Colors.white, size: 18), const SizedBox(width: 7), Text('Tambah Wallet', style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800))]))));
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => ListView(padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 20), children: [_Header(onAdd: onAdd, onTransfer: () {}), const SizedBox(height: 105), Container(width: 76, height: 76, margin: const EdgeInsets.symmetric(horizontal: 130), decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.primary, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .28), blurRadius: 30)]), child: const Icon(LucideIcons.walletMinimal, size: 34, color: Colors.white)), const SizedBox(height: 18), Text('Belum Ada Wallet', textAlign: TextAlign.center, style: AppTypography.heading2.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Text('Tambahkan rekening bank, e-wallet, uang tunai, atau investasi untuk mulai mengelola asetmu.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(height: 1.5))), const SizedBox(height: 20), Padding(padding: const EdgeInsets.symmetric(horizontal: 34), child: _AddWalletInline(onTap: onAdd))]);
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: .10), shape: BoxShape.circle), child: const Icon(LucideIcons.triangleAlert, color: AppColors.warning, size: 28)), const SizedBox(height: 12), Text('Wallet gagal dimuat', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(message, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.caption), const SizedBox(height: 14), TextButton.icon(onPressed: onRetry, icon: const Icon(LucideIcons.refreshCw), label: const Text('Coba lagi'))])));
}
