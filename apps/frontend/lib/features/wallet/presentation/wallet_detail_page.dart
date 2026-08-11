import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_model.dart';

class WalletDetailPage extends ConsumerStatefulWidget {
  const WalletDetailPage({super.key, required this.walletId});
  final String walletId;
  @override
  ConsumerState<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends ConsumerState<WalletDetailPage> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(visibleWalletsProvider).where((item) => item.id == widget.walletId).firstOrNull;
    if (wallet == null) return _NotFound();
    return PremiumScaffold(
      child: RefreshIndicator(
        color: AppColors.primaryLight,
        backgroundColor: AppColors.card,
        onRefresh: () => ref.read(walletProvider.notifier).refreshWallets(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context) + 24),
          children: [
            _TopBar(name: wallet.name),
            const SizedBox(height: 14),
            _BalanceHero(wallet: wallet, visible: _visible, onToggle: () => setState(() => _visible = !_visible)),
            const SizedBox(height: 14),
            _QuickActions(),
            const SizedBox(height: 18),
            const _SectionTitle('Ringkasan'),
            const SizedBox(height: 9),
            _StatsGrid(wallet: wallet),
            const SizedBox(height: 18),
            const _SectionTitle('Informasi Wallet'),
            const SizedBox(height: 9),
            _InfoCard(wallet: wallet),
            const SizedBox(height: 18),
            const _SectionTitle('Nexora AI'),
            const SizedBox(height: 9),
            _AiCard(wallet: wallet),
            const SizedBox(height: 18),
            _DangerActions(wallet: wallet),
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PremiumScaffold(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(LucideIcons.walletCards, size: 42, color: AppColors.textSecondary),
    const SizedBox(height: 12),
    Text('Wallet tidak ditemukan', style: AppTypography.heading2),
    const SizedBox(height: 6),
    Text('Wallet mungkin sudah dihapus atau disembunyikan.', textAlign: TextAlign.center, style: AppTypography.bodySmall),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: () => context.pop(), icon: const Icon(LucideIcons.arrowLeft), label: const Text('Kembali')),
  ]))));
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Row(children: [
    IconButton(onPressed: () => context.pop(), icon: const Icon(LucideIcons.arrowLeft)),
    Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading2)),
    IconButton(onPressed: () => _showMore(context), icon: const Icon(LucideIcons.ellipsis)),
  ]);
  void _showMore(BuildContext context) => showModalBottomSheet<void>(context: context, backgroundColor: AppColors.card, showDragHandle: true, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
    ListTile(leading: const Icon(LucideIcons.pencil), title: const Text('Edit wallet'), onTap: () => Navigator.pop(context)),
    ListTile(leading: const Icon(LucideIcons.star), title: const Text('Jadikan utama'), onTap: () => Navigator.pop(context)),
    ListTile(leading: const Icon(LucideIcons.eyeOff), title: const Text('Sembunyikan wallet'), onTap: () => Navigator.pop(context)),
  ])));
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.wallet, required this.visible, required this.onToggle});
  final WalletModel wallet; final bool visible; final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.fromLTRB(17, 17, 17, 18), borderRadius: AppRadius.radiusXXL,
    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF171525), Color(0xFF11111A), Color(0xFF0C0D13)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .14), borderRadius: AppRadius.radiusLG), child: Icon(walletTypeIcon(wallet.type), color: AppColors.primaryLight, size: 23)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(wallet.name, style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800)), Text('${wallet.bankName} • ${wallet.maskedAccount}', style: AppTypography.caption)])),
        if (wallet.isPrimary) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .16), borderRadius: AppRadius.radiusPill), child: Text('PRIMARY', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 8, fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 20),
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Saldo tersedia', style: AppTypography.bodySmall), const SizedBox(height: 3), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(visible ? rupiah(wallet.balance) : 'Rp •••••••••', style: AppTypography.displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)))])), GestureDetector(onTap: onToggle, child: Icon(visible ? LucideIcons.eye : LucideIcons.eyeOff, size: 19, color: AppColors.textSecondary))]),
    ]),
  );
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _Action(icon: LucideIcons.arrowDownLeft, label: 'Pemasukan', onTap: () => context.push('/add-income'))),
    const SizedBox(width: 8),
    Expanded(child: _Action(icon: LucideIcons.arrowUpRight, label: 'Pengeluaran', onTap: () => context.push('/add-expense'))),
    const SizedBox(width: 8),
    Expanded(child: _Action(icon: LucideIcons.arrowLeftRight, label: 'Transfer', onTap: () => context.push('/transactions'))),
  ]);
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(borderRadius: AppRadius.radiusXL, onTap: onTap, child: PremiumCard(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6), borderRadius: AppRadius.radiusXL, child: Column(children: [Icon(icon, size: 19, color: AppColors.primaryLight), const SizedBox(height: 6), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700))])));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title); final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800));
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.wallet}); final WalletModel wallet;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _Stat(icon: LucideIcons.wallet, title: 'Tipe', value: _type(wallet.type))),
    const SizedBox(width: 8),
    Expanded(child: _Stat(icon: LucideIcons.shieldCheck, title: 'Status', value: wallet.isHidden ? 'Tersembunyi' : 'Aktif')),
    const SizedBox(width: 8),
    Expanded(child: _Stat(icon: LucideIcons.badgeCheck, title: 'Peran', value: wallet.isPrimary ? 'Utama' : 'Biasa')),
  ]);
  String _type(WalletType type) { switch (type) { case WalletType.bank: return 'Bank'; case WalletType.ewallet: return 'E-Wallet'; case WalletType.cash: return 'Cash'; case WalletType.investment: return 'Investasi'; } }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.title, required this.value});
  final IconData icon; final String title; final String value;
  @override
  Widget build(BuildContext context) => PremiumCard(padding: const EdgeInsets.fromLTRB(8, 10, 8, 11), borderRadius: AppRadius.radiusXL, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 17, color: AppColors.primaryLight), const SizedBox(height: 7), Text(title, style: AppTypography.caption), const SizedBox(height: 2), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800))]);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.wallet}); final WalletModel wallet;
  @override
  Widget build(BuildContext context) => PremiumCard(padding: const EdgeInsets.symmetric(vertical: 5), borderRadius: AppRadius.radiusXL, child: Column(children: [
    _InfoRow(label: 'Nama wallet', value: wallet.name), _InfoRow(label: 'Penyedia', value: wallet.bankName), _InfoRow(label: 'Nomor akun', value: wallet.maskedAccount), _InfoRow(label: 'ID wallet', value: wallet.id),
  ]));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value}); final String label; final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10), child: Row(children: [Expanded(child: Text(label, style: AppTypography.bodySmall)), const SizedBox(width: 12), Flexible(child: Text(value, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)))]));
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.wallet}); final WalletModel wallet;
  @override
  Widget build(BuildContext context) {
    final advice = wallet.balance <= 0 ? 'Saldo wallet ini kosong. Isi hanya jika memang punya fungsi yang jelas.' : wallet.isPrimary ? 'Wallet utama sebaiknya fokus pada dana operasional. Pisahkan dana tujuan agar arus kas lebih mudah dikontrol.' : 'Wallet ini bisa menjadi kantong khusus agar distribusi aset lebih mudah dipantau.';
    return Container(padding: const EdgeInsets.fromLTRB(13, 12, 13, 13), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B0A12), Color(0xFF24133E)]), borderRadius: AppRadius.radiusXXL, border: Border.all(color: AppColors.primaryLight.withValues(alpha: .14))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(LucideIcons.sparkles, color: AppColors.primaryLight, size: 19), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Insight wallet', style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(advice, style: AppTypography.caption.copyWith(height: 1.45))]))]));
  }
}

class _DangerActions extends ConsumerWidget {
  const _DangerActions({required this.wallet}); final WalletModel wallet;
  @override
  Widget build(BuildContext context, WidgetRef ref) => PremiumCard(padding: EdgeInsets.zero, borderRadius: AppRadius.radiusXL, child: Column(children: [
    ListTile(leading: const Icon(LucideIcons.pencil, size: 19), title: const Text('Edit wallet'), subtitle: const Text('Ubah nama dan detail wallet'), onTap: () {}),
    ListTile(leading: const Icon(LucideIcons.trash2, size: 19, color: AppColors.error), title: const Text('Hapus wallet'), subtitle: const Text('Riwayat transaksi tidak ikut dihapus'), onTap: () => _confirmDelete(context, ref)),
  ]));
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Hapus wallet?'), content: const Text('Wallet akan dihapus dari daftar.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus'))]));
    if (confirmed == true && context.mounted) {
      final ok = await ref.read(walletProvider.notifier).deleteWallet(wallet.id);
      if (ok && context.mounted) context.pop();
    }
  }
}
