import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
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
        error: (error, _) => _WalletErrorState(
          message: error.toString(),
          onRetry: () => ref.read(walletProvider.notifier).refreshWallets(),
        ),
        data: (_) {
          if (wallets.isEmpty) {
            return _WalletEmptyContent(onAddWallet: widget.onAddWallet);
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: () => ref.read(walletProvider.notifier).refreshWallets(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: AppSpacing.screen.copyWith(
                bottom: AppSpacing.bottomNav(context) + 24,
              ),
              children: [
                _WalletTopBar(
                  onRefresh: () =>
                      ref.read(walletProvider.notifier).refreshWallets(),
                  onAdd: widget.onAddWallet,
                ),
                const SizedBox(height: 18),
                _TotalAssetsCard(
                  balance: totalBalance,
                  visible: _isBalanceVisible,
                  onToggle: () => setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  }),
                ),
                if (primaryWallet != null) ...[
                  const SizedBox(height: 16),
                  _PrimaryWalletCard(
                    wallet: primaryWallet,
                    onTap: () => widget.onWalletTap?.call(primaryWallet.id),
                  ),
                ],
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Ringkasan Wallet'),
                const SizedBox(height: 12),
                _WalletTypeGrid(wallets: wallets),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Semua Wallet',
                  trailing: '${wallets.length} akun',
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < wallets.length; index++) ...[
                  _WalletListTile(
                    wallet: wallets[index],
                    onTap: () =>
                        widget.onWalletTap?.call(wallets[index].id),
                  ),
                  if (index != wallets.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WalletTopBar extends StatelessWidget {
  const _WalletTopBar({this.onRefresh, this.onAdd});

  final VoidCallback? onRefresh;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wallet', style: AppTypography.heading1),
              const SizedBox(height: 2),
              Text('Kelola semua asetmu', style: AppTypography.bodySmall),
            ],
          ),
        ),
        _CircleAction(icon: LucideIcons.refreshCw, onPressed: onRefresh),
        const SizedBox(width: 10),
        _AddWalletButton(onPressed: onAdd),
      ],
    );
  }
}

class _TotalAssetsCard extends StatelessWidget {
  const _TotalAssetsCard({
    required this.balance,
    required this.visible,
    required this.onToggle,
  });

  final double balance;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      borderRadius: AppRadius.radiusXXL,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF202A40), Color(0xFF151C2A)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Total Assets', style: AppTypography.bodySmall),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  visible ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            visible ? rupiah(balance) : 'Rp •••••••••',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .13),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.trendingUp, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text('+4.8%', style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('bulan ini', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryWalletCard extends StatelessWidget {
  const _PrimaryWalletCard({required this.wallet, this.onTap});

  final WalletModel wallet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusXXL,
      child: PremiumCard(
        padding: const EdgeInsets.all(18),
        borderRadius: AppRadius.radiusXXL,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [wallet.color.withValues(alpha: .22), const Color(0xFF171D2B)],
        ),
        child: Row(
          children: [
            PremiumIconBadge(icon: wallet.icon, color: wallet.color, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Wallet Utama', style: AppTypography.caption),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .14),
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: Text('PRIMARY', style: AppTypography.caption.copyWith(color: AppColors.primaryLight, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(wallet.name, style: AppTypography.labelLarge),
                  Text(wallet.maskedAccount, style: AppTypography.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              rupiah(wallet.balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTypeGrid extends StatelessWidget {
  const _WalletTypeGrid({required this.wallets});

  final List<WalletModel> wallets;

  @override
  Widget build(BuildContext context) {
    final types = <WalletType>[
      WalletType.bank,
      WalletType.ewallet,
      WalletType.cash,
      WalletType.investment,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 92,
      ),
      itemBuilder: (context, index) {
        final type = types[index];
        final items = wallets.where((wallet) => wallet.type == type);
        final total = items.fold<double>(0, (sum, wallet) => sum + wallet.balance);
        final sample = items.firstOrNull;
        final color = sample?.color ?? _typeColor(type);

        return PremiumCard(
          padding: const EdgeInsets.all(13),
          borderRadius: AppRadius.radiusXL,
          child: Row(
            children: [
              PremiumIconBadge(icon: _typeIcon(type), color: color, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_typeLabel(type), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                    const SizedBox(height: 2),
                    Text(rupiah(total), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _typeColor(WalletType type) {
    switch (type) {
      case WalletType.bank:
        return AppColors.primary;
      case WalletType.ewallet:
        return AppColors.info;
      case WalletType.cash:
        return AppColors.warning;
      case WalletType.investment:
        return AppColors.success;
    }
  }

  IconData _typeIcon(WalletType type) {
    switch (type) {
      case WalletType.bank:
        return LucideIcons.landmark;
      case WalletType.ewallet:
        return LucideIcons.walletMinimal;
      case WalletType.cash:
        return LucideIcons.banknote;
      case WalletType.investment:
        return LucideIcons.chartColumn;
    }
  }

  String _typeLabel(WalletType type) {
    switch (type) {
      case WalletType.bank:
        return 'Bank';
      case WalletType.ewallet:
        return 'E-Wallet';
      case WalletType.cash:
        return 'Cash';
      case WalletType.investment:
        return 'Investasi';
    }
  }
}

class _WalletListTile extends StatelessWidget {
  const _WalletListTile({required this.wallet, this.onTap});

  final WalletModel wallet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusXL,
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        borderRadius: AppRadius.radiusXL,
        child: Row(
          children: [
            PremiumIconBadge(icon: wallet.icon, color: wallet.color, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wallet.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${wallet.bankName} • ${wallet.maskedAccount}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(rupiah(wallet.balance), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800))),
        if (trailing != null)
          Text(trailing!, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .05),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 52, height: 52, child: Icon(icon, color: AppColors.textPrimary, size: 23)),
      ),
    );
  }
}

class _AddWalletButton extends StatelessWidget {
  const _AddWalletButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(width: 58, height: 58, child: Icon(LucideIcons.plus, color: Colors.white, size: 28)),
      ),
    );
  }
}

class _WalletEmptyContent extends StatelessWidget {
  const _WalletEmptyContent({this.onAddWallet});

  final VoidCallback? onAddWallet;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)),
      children: [
        const _WalletTopBar(),
        const SizedBox(height: 30),
        WalletEmptyState(onAddWallet: onAddWallet),
      ],
    );
  }
}

class _WalletLoadingState extends StatelessWidget {
  const _WalletLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)),
      children: const [
        ShimmerSkeleton(width: 140, height: 30),
        SizedBox(height: 8),
        ShimmerSkeleton(width: 210, height: 18),
        SizedBox(height: 20),
        ShimmerSkeleton(height: 190),
        SizedBox(height: 14),
        ShimmerSkeleton(height: 90),
        SizedBox(height: 22),
        ShimmerSkeleton(height: 92),
        SizedBox(height: 10),
        ShimmerSkeleton(height: 92),
      ],
    );
  }
}

class _WalletErrorState extends StatelessWidget {
  const _WalletErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: EmptyStateCard(
          icon: LucideIcons.triangleAlert,
          title: 'Wallet belum tersedia',
          message: message,
          action: 'Coba Lagi',
          onPressed: onRetry,
        ),
      ),
    );
  }
}
