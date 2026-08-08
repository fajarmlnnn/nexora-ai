import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../models/dashboard_summary.dart';
import '../../../core/widgets/premium_widgets.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return NCard(
      gradient: AppGradients.balanceCard,
      showBorder: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Good Morning 👋",
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Fajar",
                    style: AppTypography.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            "Total Balance",
            style: AppTypography.caption.copyWith(color: Colors.white70),
          ),

          const SizedBox(height: 4),

          Text(
            rupiah(summary.totalBalance),
            style: AppTypography.heading3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.success, size: 16),

              const SizedBox(width: 4),

              Text(
                "+12.4% bulan ini",
                style: AppTypography.caption.copyWith(color: AppColors.success),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(height: 1, color: Colors.white.withValues(alpha: .08)),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _MiniFinance(
                  "Income",
                  rupiah(summary.monthlyIncome),
                  AppColors.success,
                ),
              ),

              Container(width: 1, height: 28, color: Colors.white12),

              Expanded(
                child: _MiniFinance(
                  "Expense",
                  rupiah(summary.monthlyExpense),
                  AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniFinance extends StatelessWidget {
  const _MiniFinance(this.title, this.value, this.color);

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.caption.copyWith(color: Colors.white60),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
