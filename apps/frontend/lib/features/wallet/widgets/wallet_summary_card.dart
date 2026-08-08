import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/wallet_model.dart';

class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({
    super.key,
    required this.wallets,
    this.onCategoryTap,
  });

  final List<WalletModel> wallets;
  final ValueChanged<WalletType>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final summaries = [
      _WalletSummary(
        type: WalletType.bank,
        label: 'Bank',
        icon: LucideIcons.landmark,
        color: AppColors.primary,
      ),
      _WalletSummary(
        type: WalletType.ewallet,
        label: 'E-Wallet',
        icon: LucideIcons.walletMinimal,
        color: AppColors.info,
      ),
      _WalletSummary(
        type: WalletType.cash,
        label: 'Cash',
        icon: LucideIcons.banknote,
        color: AppColors.warning,
      ),
      _WalletSummary(
        type: WalletType.investment,
        label: 'Investasi',
        icon: LucideIcons.chartColumn,
        color: AppColors.success,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusXXL,
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Wallet',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Distribusi saldo kamu',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: .55),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .05),
                  borderRadius: AppRadius.radiusLG,
                ),
                child: const Icon(
                  LucideIcons.chartPie,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          AppSpacing.gapLG,

          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 10.0;
              final itemWidth = (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final summary in summaries)
                    SizedBox(
                      width: itemWidth,
                      child: _SummaryItem(
                        summary: summary,
                        balance: _balanceFor(summary.type),
                        onTap: onCategoryTap == null
                            ? null
                            : () => onCategoryTap!(summary.type),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  double _balanceFor(WalletType type) {
    return wallets
        .where((wallet) => wallet.type == type && !wallet.isHidden)
        .fold<double>(0, (total, wallet) => total + wallet.balance);
  }
}

class _WalletSummary {
  const _WalletSummary({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });

  final WalletType type;
  final String label;
  final IconData icon;
  final Color color;
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.summary,
    required this.balance,
    this.onTap,
  });

  final _WalletSummary summary;
  final double balance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusXL,
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .035),
            borderRadius: AppRadius.radiusXL,
            border: Border.all(color: Colors.white.withValues(alpha: .05)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: summary.color.withValues(alpha: .12),
                  borderRadius: AppRadius.radiusLG,
                  boxShadow: [
                    BoxShadow(
                      color: summary.color.withValues(alpha: .10),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(summary.icon, color: summary.color, size: 19),
              ),

              AppSpacing.hGapSM,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: .62),
                      ),
                    ),
                    const SizedBox(height: 3),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: balance),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          _formatRupiah(value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ],
                ),
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
