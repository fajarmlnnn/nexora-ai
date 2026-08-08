import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/wallet_model.dart';

class WalletAccountTile extends StatelessWidget {
  const WalletAccountTile({
    super.key,
    required this.wallet,
    this.onTap,
    this.onMoreTap,
  });

  final WalletModel wallet;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusXL,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .035),
            borderRadius: AppRadius.radiusXL,
            border: Border.all(color: Colors.white.withValues(alpha: .055)),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              _AccountIcon(wallet: wallet),

              AppSpacing.hGapMD,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wallet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (wallet.isPrimary) const _PrimaryDot(),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${wallet.bankName} • ${wallet.maskedAccount}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: .58),
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.hGapSM,

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatRupiah(wallet.balance),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  InkWell(
                    onTap: onMoreTap,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.ellipsis,
                        size: 17,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

class _AccountIcon extends StatelessWidget {
  const _AccountIcon({required this.wallet});

  final WalletModel wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            wallet.color.withValues(alpha: .28),
            wallet.color.withValues(alpha: .08),
          ],
        ),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: wallet.color.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: wallet.color.withValues(alpha: .12),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(wallet.icon, color: wallet.color, size: 21),
    );
  }
}

class _PrimaryDot extends StatelessWidget {
  const _PrimaryDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(left: 6),
      decoration: const BoxDecoration(
        color: Colors.white70,
        shape: BoxShape.circle,
      ),
    );
  }
}
