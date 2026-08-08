import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class WalletHeader extends StatelessWidget {
  const WalletHeader({
    super.key,
    required this.totalBalance,
    this.isBalanceVisible = true,
    this.onToggleBalance,
    this.onAddWallet,
    this.onRefresh,
  });

  final double totalBalance;
  final bool isBalanceVisible;
  final VoidCallback? onToggleBalance;
  final VoidCallback? onAddWallet;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet',
                    style: AppTypography.heading2.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola semua asetmu',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            _HeaderButton(icon: LucideIcons.refreshCw, onTap: onRefresh),

            const SizedBox(width: 8),

            _HeaderButton(
              icon: LucideIcons.plus,
              onTap: onAddWallet,
              filled: true,
            ),
          ],
        ),

        AppSpacing.gapLG,

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF202A3B), Color(0xFF161E2C), Color(0xFF101722)],
            ),
            borderRadius: AppRadius.radiusXXL,
            border: Border.all(color: Colors.white.withValues(alpha: .07)),
            boxShadow: AppShadows.card,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -40,
                child: _Glow(color: AppColors.primary, size: 120),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Total Assets',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: .62),
                        ),
                      ),

                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: onToggleBalance,
                        child: Icon(
                          isBalanceVisible
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                          size: 16,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      isBalanceVisible
                          ? _formatRupiah(totalBalance)
                          : 'Rp ••••••••',
                      key: ValueKey(isBalanceVisible),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.trendingUp,
                              size: 13,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '+4.8%',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        'bulan ini',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: .52),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRupiah(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final position = digits.length - i;

      buffer.write(digits[i]);

      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp$buffer';
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLG,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: filled
                ? AppColors.primary
                : Colors.white.withValues(alpha: .05),
            borderRadius: AppRadius.radiusLG,
            border: Border.all(
              color: Colors.white.withValues(alpha: filled ? 0 : .06),
            ),
            boxShadow: filled ? AppShadows.button : null,
          ),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .10),
            blurRadius: size * .45,
            spreadRadius: size * .04,
          ),
        ],
      ),
    );
  }
}
