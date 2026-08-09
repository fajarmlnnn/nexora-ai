import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/wallet_controller.dart';
import '../widgets/wallet_account_tile.dart';
import '../widgets/wallet_card.dart';
import '../widgets/wallet_empty_state.dart';
import '../widgets/wallet_header.dart';
import '../widgets/wallet_summary_card.dart';

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
    final visibleWallets = ref.watch(visibleWalletsProvider);

    return PremiumScaffold(
      child: walletsAsync.when(
        loading: () => const _WalletLoadingState(),
        error: (error, stackTrace) {
          return _WalletErrorState(
            message: error.toString(),
            onRetry: () {
              ref.read(walletProvider.notifier).refreshWallets();
            },
          );
        },
        data: (_) {
          if (visibleWallets.isEmpty) {
            return _WalletEmptyContent(onAddWallet: widget.onAddWallet);
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: () {
              return ref.read(walletProvider.notifier).refreshWallets();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: AppSpacing.screen.copyWith(
                bottom: AppSpacing.bottomNav(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WalletHeader(
                    totalBalance: totalBalance,
                    isBalanceVisible: _isBalanceVisible,
                    onToggleBalance: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                    onAddWallet: widget.onAddWallet,
                    onRefresh: () {
                      ref.read(walletProvider.notifier).refreshWallets();
                    },
                  ),
                  AppSpacing.gapLG,
                  if (primaryWallet != null) ...[
                    WalletCard(
                      wallet: primaryWallet,
                      onTap: () {
                        widget.onWalletTap?.call(primaryWallet.id);
                      },
                    ),
                    AppSpacing.gapLG,
                  ],
                  WalletSummaryCard(
                    wallets: visibleWallets,
                    onCategoryTap: (type) {
                      // Filter wallet dapat ditambahkan di tahap berikutnya.
                    },
                  ),
                  AppSpacing.gapLG,
                  _WalletSectionHeader(
                    title: 'Semua Wallet',
                    count: visibleWallets.length,
                  ),
                  AppSpacing.gapMD,
                  for (var index = 0; index < visibleWallets.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleWallets.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: WalletAccountTile(
                        wallet: visibleWallets[index],
                        onTap: () {
                          widget.onWalletTap?.call(visibleWallets[index].id);
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WalletEmptyContent extends StatelessWidget {
  const _WalletEmptyContent({this.onAddWallet});

  final VoidCallback? onAddWallet;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screen.copyWith(
        bottom: AppSpacing.bottomNav(context),
      ),
      child: SizedBox(
        width: double.infinity,
        child: PremiumEntrance(
          child: WalletEmptyState(onAddWallet: onAddWallet),
        ),
      ),
    );
  }
}

class _WalletLoadingState extends StatelessWidget {
  const _WalletLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screen.copyWith(
        bottom: AppSpacing.bottomNav(context),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumEntrance(child: ShimmerSkeleton(width: 150, height: 30)),
          SizedBox(height: 8),
          PremiumEntrance(
            delay: Duration(milliseconds: 40),
            child: ShimmerSkeleton(width: 220, height: 18),
          ),
          SizedBox(height: 24),
          PremiumEntrance(
            delay: Duration(milliseconds: 80),
            child: ShimmerSkeleton(height: 220),
          ),
          SizedBox(height: 20),
          PremiumEntrance(
            delay: Duration(milliseconds: 120),
            child: ShimmerSkeleton(height: 230),
          ),
          SizedBox(height: 20),
          PremiumEntrance(
            delay: Duration(milliseconds: 160),
            child: ShimmerSkeleton(height: 76),
          ),
          SizedBox(height: 10),
          PremiumEntrance(
            delay: Duration(milliseconds: 200),
            child: ShimmerSkeleton(height: 76),
          ),
          SizedBox(height: 10),
          PremiumEntrance(
            delay: Duration(milliseconds: 240),
            child: ShimmerSkeleton(height: 76),
          ),
        ],
      ),
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

class _WalletSectionHeader extends StatelessWidget {
  const _WalletSectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .06),
            borderRadius: AppRadius.radiusLG,
            border: Border.all(color: Colors.white.withValues(alpha: .05)),
          ),
          child: Text(
            '$count akun',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
