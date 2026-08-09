import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/scrolling_text.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_model.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key, this.onAddWallet, this.onWalletTap});
  final VoidCallback? onAddWallet;
  final ValueChanged<String>? onWalletTap;
  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  bool _isBalanceVisible = true;
  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletProvider);
    final totalBalance = ref.watch(totalWalletBalanceProvider);
    final primaryWallet = ref.watch(primaryWalletProvider);
    final wallets = ref.watch(visibleWalletsProvider);
    return PremiumScaffold(
      child: walletsAsync.when(
        loading: () => const _WalletLoadingState(),
        error: (error, _) => _WalletErrorState(message: error.toString(), onRetry: () => ref.read(walletProvider.notifier).refreshWallets()),
        data: (_) {
          if (wallets.isEmpty) return _WalletEmptyContent(onAddWallet: widget.onAddWallet);
          return RefreshIndicator(
            color: AppColors.primaryLight,
            backgroundColor: AppColors.card,
            onRefresh: () => ref.read(walletProvider.notifier).refreshWallets(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 18),
              children: [
                _WalletHeader(onRefresh: () => ref.read(walletProvider.notifier).refreshWallets(), onAdd: widget.onAddWallet),
                const SizedBox(height: 14),
                _TotalAssetsCard(balance: totalBalance, visible: _isBalanceVisible, onToggle: () => setState(() => _isBalanceVisible = !_isBalanceVisible)),
                if (primaryWallet != null) ...[
                  const SizedBox(height: 10),
                  _PrimaryWalletCard(wallet: primaryWallet, onTap: () => widget.onWalletTap?.call(primaryWallet.id)),
                ],
                const SizedBox(height: 18),
                const _SectionHeader(title: 'Ringkasan Wallet'),
                const SizedBox(height: 9),
                _WalletSummaryRow(wallets: wallets),
                const SizedBox(height: 18),
                _SectionHeader(title: 'Semua Wallet', trailing: '${wallets.length} akun'),
                const SizedBox(height: 8),
                for (var index = 0; index < wallets.length; index++) ...[
                  _WalletListTile(wallet: wallets[index], onTap: () => widget.onWalletTap?.call(wallets[index].id)),
                  if (index != wallets.length - 1) const SizedBox(height: 5),
                ],
                const SizedBox(height: 16),
                const _WalletAiInsight(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({this.onRefresh, this.onAdd});
  final VoidCallback? onRefresh;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Wallet', style: AppTypography.heading1),
      Text('Kelola semua asetmu', style: AppTypography.bodySmall),
    ])),
    _HeaderButton(icon: LucideIcons.refreshCw, onTap: onRefresh),
    const SizedBox(width: 8),
    Material(color: AppColors.primary, shape: const CircleBorder(), child: InkWell(onTap: onAdd, customBorder: const CircleBorder(), child: const SizedBox(width: 50, height: 50, child: Icon(LucideIcons.plus, color: Colors.white, size: 25)))),
  ]);
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(color: Colors.white.withValues(alpha: .055), shape: const CircleBorder(), child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: SizedBox(width: 46, height: 46, child: Icon(icon, size: 21, color: AppColors.textPrimary))));
}

class _TotalAssetsCard extends StatelessWidget {
  const _TotalAssetsCard({required this.balance, required this.visible, required this.onToggle});
  final double balance;
  final bool visible;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
    borderRadius: AppRadius.radiusXXL,
    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF201B4F), Color(0xFF141A29), Color(0xFF151C2B)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Total Aset', style: AppTypography.bodySmall),
        const SizedBox(width: 6),
        GestureDetector(onTap: onToggle, child: Icon(visible ? LucideIcons.eye : LucideIcons.eyeOff, size: 17, color: AppColors.textSecondary)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .055), borderRadius: AppRadius.radiusPill, border: Border.all(color: AppColors.border.withValues(alpha: .45))), child: Text('Bulan ini', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: ScrollingText(text: visible ? rupiah(balance) : 'Rp •••••••••', style: AppTypography.displaySmall.copyWith(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 31))),
        const SizedBox(width: 8),
        const SizedBox(width: 110, height: 45, child: _AssetSparkline()),
      ]),
      const SizedBox(height: 5),
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .13), borderRadius: AppRadius.radiusPill), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.trendingUp, size: 14, color: AppColors.success), const SizedBox(width: 4), Text('+4.8%', style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w800))])),
        const SizedBox(width: 8),
        Text('vs bulan lalu', style: AppTypography.bodySmall),
      ]),
    ]),
  );
}

class _AssetSparkline extends StatelessWidget {
  const _AssetSparkline();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SparklinePainter());
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(0, size.height * .72), Offset(size.width * .12, size.height * .56), Offset(size.width * .23, size.height * .65), Offset(size.width * .36, size.height * .34), Offset(size.width * .49, size.height * .52), Offset(size.width * .62, size.height * .28), Offset(size.width * .76, size.height * .38), Offset(size.width * .89, size.height * .18), Offset(size.width, size.height * .08),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }
    final glow = Paint()..color = AppColors.primaryLight.withValues(alpha: .20)..style = PaintingStyle.stroke..strokeWidth = 7..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final line = Paint()..color = AppColors.primaryLight..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
    canvas.drawCircle(points.last, 3.5, Paint()..color = AppColors.primaryLight);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrimaryWalletCard extends StatelessWidget {
  const _PrimaryWalletCard({required this.wallet, this.onTap});
  final WalletModel wallet;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadius.radiusXXL,
    child: PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      borderRadius: AppRadius.radiusXXL,
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [wallet.color.withValues(alpha: .28), const Color(0xFF171D2B)]),
      child: Row(children: [
        PremiumIconBadge(icon: wallet.icon, color: wallet.color, size: 46),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('Akun Utama', style: AppTypography.caption), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .16), borderRadius: AppRadius.radiusPill), child: Text('PRIMARY', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 8, fontWeight: FontWeight.w800)))]),
          const SizedBox(height: 2),
          Text(wallet.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
          Text(wallet.maskedAccount, style: AppTypography.caption),
        ])),
        const SizedBox(width: 8),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Saldo', style: AppTypography.caption),
          ScrollingText(text: rupiah(wallet.balance), style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800), alignment: Alignment.centerRight),
          const SizedBox(height: 2),
          const Icon(LucideIcons.chevronRight, size: 17, color: AppColors.primaryLight),
        ])),
      ]),
    ),
  );
}

class _WalletSummaryRow extends StatelessWidget {
  const _WalletSummaryRow({required this.wallets});
  final List<WalletModel> wallets;
  @override
  Widget build(BuildContext context) {
    const types = [WalletType.bank, WalletType.ewallet, WalletType.cash, WalletType.investment];
    return Row(children: [for (var index = 0; index < types.length; index++) ...[if (index != 0) const SizedBox(width: 6), Expanded(child: _SummaryItem(type: types[index], wallets: wallets))]]);
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.type, required this.wallets});
  final WalletType type;
  final List<WalletModel> wallets;
  @override
  Widget build(BuildContext context) {
    final items = wallets.where((wallet) => wallet.type == type);
    final total = items.fold<double>(0, (sum, wallet) => sum + wallet.balance);
    final sample = items.firstOrNull;
    final color = sample?.color ?? _typeColor(type);
    return PremiumCard(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9), borderRadius: AppRadius.radiusXL, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PremiumIconBadge(icon: _typeIcon(type), color: color, size: 31),
      const SizedBox(height: 6),
      Text(_typeLabel(type), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
      const SizedBox(height: 1),
      ScrollingText(text: rupiah(total), style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
    ]));
  }
  Color _typeColor(WalletType type) {
    switch (type) {
      case WalletType.bank: return AppColors.primary;
      case WalletType.ewallet: return AppColors.info;
      case WalletType.cash: return AppColors.warning;
      case WalletType.investment: return AppColors.success;
    }
  }
  IconData _typeIcon(WalletType type) {
    switch (type) {
      case WalletType.bank: return LucideIcons.landmark;
      case WalletType.ewallet: return LucideIcons.walletMinimal;
      case WalletType.cash: return LucideIcons.banknote;
      case WalletType.investment: return LucideIcons.chartColumn;
    }
  }
  String _typeLabel(WalletType type) {
    switch (type) {
      case WalletType.bank: return 'Bank';
      case WalletType.ewallet: return 'E-Wallet';
      case WalletType.cash: return 'Cash';
      case WalletType.investment: return 'Investasi';
    }
  }
}

class _WalletListTile extends StatelessWidget {
  const _WalletListTile({required this.wallet, this.onTap});
  final WalletModel wallet;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadius.radiusXL,
    child: PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      borderRadius: AppRadius.radiusXL,
      child: Row(children: [
        PremiumIconBadge(icon: wallet.icon, color: wallet.color, size: 38),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(wallet.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700))),
            if (wallet.isPrimary) ...[const SizedBox(width: 5), Text('PRIMARY', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 8, fontWeight: FontWeight.w800))],
          ]),
          const SizedBox(height: 1),
          Text('${wallet.bankName} • ${wallet.maskedAccount}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
        ])),
        const SizedBox(width: 7),
        Flexible(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Flexible(child: ScrollingText(text: rupiah(wallet.balance), style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800), alignment: Alignment.centerRight)),
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronRight, size: 15, color: AppColors.textSecondary),
        ])),
      ]),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800))), if (trailing != null) Text(trailing!, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700))]);
}

class _WalletAiInsight extends StatelessWidget {
  const _WalletAiInsight();
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.fromLTRB(10, 9, 12, 10),
    borderRadius: AppRadius.radiusXXL,
    gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF201B4A), Color(0xFF4A2A91)]),
    child: Row(children: [
      SizedBox(width: 82, height: 86, child: Stack(alignment: Alignment.center, children: [
        Container(width: 66, height: 66, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primaryLight.withValues(alpha: .26), blurRadius: 30)])),
        SvgPicture.asset('assets/mascot/nexora_mascot_master.svg', width: 78, height: 78),
      ])),
      const SizedBox(width: 7),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primaryLight), const SizedBox(width: 5), Text('Nexora AI', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .18), borderRadius: AppRadius.radiusPill), child: Text('AI', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 8, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 3),
        Text('Nexora AI Insight', style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text('Pengeluaran makan & minummu naik 18% dibanding bulan lalu. Saatnya atur budget!', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: .72), height: 1.25)),
        const SizedBox(height: 5),
        Text('Lihat Insight  →', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800)),
      ])),
      const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.primaryLight),
    ]),
  );
}

class _WalletEmptyContent extends StatelessWidget {
  const _WalletEmptyContent({this.onAddWallet});
  final VoidCallback? onAddWallet;
  @override
  Widget build(BuildContext context) => ListView(padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)), children: [_WalletHeader(onAdd: onAddWallet), const SizedBox(height: 20), WalletEmptyState(onAddWallet: onAddWallet)]);
}

class _WalletLoadingState extends StatelessWidget {
  const _WalletLoadingState();
  @override
  Widget build(BuildContext context) => ListView(padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)), children: const [ShimmerSkeleton(width: 140, height: 30), SizedBox(height: 6), ShimmerSkeleton(width: 190, height: 16), SizedBox(height: 14), ShimmerSkeleton(height: 150), SizedBox(height: 10), ShimmerSkeleton(height: 78), SizedBox(height: 14), ShimmerSkeleton(height: 82), SizedBox(height: 10), ShimmerSkeleton(height: 82)]);
}

class _WalletErrorState extends StatelessWidget {
  const _WalletErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: AppSpacing.screen, child: PremiumCard(padding: const EdgeInsets.all(18), borderRadius: AppRadius.radiusXL, child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.circleAlert, size: 38, color: AppColors.warning), const SizedBox(height: 10), Text('Gagal memuat wallet', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(message, textAlign: TextAlign.center, style: AppTypography.caption), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('Coba Lagi'))]))));
}
