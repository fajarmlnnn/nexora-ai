import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../models/dashboard_summary.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary});

  final DashboardSummary summary;

  String get _currency => summary.currency;

  String _money(double value) {
    return '$_currency ${value.toStringAsFixed(0)}';
  }

  String get _updated {
    final diff = DateTime.now().difference(summary.lastUpdated);

    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inHours < 1) return 'Updated ${diff.inMinutes} min ago';
    if (diff.inDays < 1) return 'Updated ${diff.inHours} h ago';

    return 'Updated ${diff.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    return NCard(
      gradient: AppGradients.balanceCard,
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              AppSpacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fajar',
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          AppSpacing.gapXL,

          Text(
            'Total Balance',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),

          const SizedBox(height: 6),

          Text(
            _money(summary.totalBalance),

            style: AppTypography.balance.copyWith(color: Colors.white),
          ),

          AppSpacing.gapXL,

          Container(height: 1, color: Colors.white.withValues(alpha: .15)),

          AppSpacing.gapLG,

          Row(
            children: [
              Expanded(
                child: _FinanceItem(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.success,
                  label: 'Income',
                  amount: _money(summary.monthlyIncome),
                ),
              ),
              AppSpacing.hGapLG,
              Expanded(
                child: _FinanceItem(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppColors.danger,
                  label: 'Expense',
                  amount: _money(summary.monthlyExpense),
                ),
              ),
            ],
          ),

          AppSpacing.gapLG,

          Container(height: 1, color: Colors.white.withValues(alpha: .15)),

          AppSpacing.gapMD,

          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: .75),
              ),
              AppSpacing.hGapXS,
              Expanded(
                child: Text(
                  _updated,
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: AppTypography.caption.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceItem extends StatelessWidget {
  const _FinanceItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              AppSpacing.hGapSM,
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),

          AppSpacing.gapMD,

          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amountSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
