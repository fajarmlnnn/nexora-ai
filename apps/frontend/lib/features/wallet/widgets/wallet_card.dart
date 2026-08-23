import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/wallet_model.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_colors.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({super.key, required this.wallet, this.onTap});

  final WalletModel wallet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'wallet_${wallet.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusXXL,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  wallet.color,
                  Color.lerp(wallet.color, Colors.black, .45) ?? wallet.color,
                  AppColors.surface,
                ],
                stops: const [0, .55, 1],
              ),
              borderRadius: AppRadius.radiusXXL,
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
              boxShadow: [
                ...AppShadows.card,
                BoxShadow(
                  color: wallet.color.withValues(alpha: .20),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Stack(
              children: [
                const _BackgroundDecoration(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _WalletIcon(wallet: wallet),

                        AppSpacing.hGapMD,

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                wallet.bankName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: .72),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (wallet.isPrimary) const _PrimaryBadge(),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Saldo',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: .68),
                      ),
                    ),

                    const SizedBox(height: 5),

                    _AnimatedBalance(amount: wallet.balance),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wallet.maskedAccount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white.withValues(alpha: .78),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          LucideIcons.arrowUpRight,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletIcon extends StatelessWidget {
  const _WalletIcon({required this.wallet});

  final WalletModel wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: wallet.color.withValues(alpha: .25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(wallet.icon, color: Colors.white, size: 22),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.star, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Utama',
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBalance extends StatelessWidget {
  const _AnimatedBalance({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: AppMotion.counter,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          _formatRupiah(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.heading2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        );
      },
    );
  }

  String _formatRupiah(double value) {
    final rounded = value.round();
    final digits = rounded.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final position = digits.length - i;

      buffer.write(digits[i]);

      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp$buffer';
  }
}

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -65,
            child: _GlowCircle(size: 160, opacity: .08),
          ),
          Positioned(
            right: 25,
            bottom: -85,
            child: _GlowCircle(size: 130, opacity: .05),
          ),
          Positioned(
            left: -40,
            bottom: -100,
            child: _GlowCircle(size: 150, opacity: .04),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: opacity),
            blurRadius: size * .35,
            spreadRadius: size * .04,
          ),
        ],
      ),
    );
  }
}
