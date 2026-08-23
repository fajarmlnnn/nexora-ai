import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class WalletEmptyState extends StatelessWidget {
  const WalletEmptyState({super.key, this.onAddWallet});

  final VoidCallback? onAddWallet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _WalletIllustration(),

            AppSpacing.gapLG,

            Text(
              'Belum Ada Wallet',
              textAlign: TextAlign.center,
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            AppSpacing.gapSM,

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Text(
                'Tambahkan rekening bank, e-wallet, uang tunai, atau investasi untuk mulai mengelola seluruh asetmu di satu tempat.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),

            AppSpacing.gapLG,

            _AddWalletButton(onTap: onAddWallet),
          ],
        ),
      ),
    );
  }
}

class _WalletIllustration extends StatelessWidget {
  const _WalletIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: .055),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .08),
                  blurRadius: 45,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: .18),
                  AppColors.primary.withValues(alpha: .06),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: AppShadows.card,
            ),
          ),

          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.radiusLG,
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(
              LucideIcons.walletMinimal,
              size: 27,
              color: AppColors.primary,
            ),
          ),

          const Positioned(right: 20, top: 18, child: _Sparkle(size: 15)),

          const Positioned(left: 17, bottom: 20, child: _Sparkle(size: 10)),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      LucideIcons.sparkles,
      size: size,
      color: AppColors.primary.withValues(alpha: .55),
    );
  }
}

class _AddWalletButton extends StatelessWidget {
  const _AddWalletButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLG,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.brand],
            ),
            borderRadius: AppRadius.radiusLG,
            boxShadow: AppShadows.button,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.plus, size: 18, color: Colors.white),

              AppSpacing.hGapSM,

              Text(
                'Tambah Wallet',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
