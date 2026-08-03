import 'package:flutter/material.dart';

import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        gradient: AppGradients.balanceCard,
        borderRadius: AppRadius.radiusXL,
        boxShadow: AppShadows.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),

          AppSpacing.gapSM,

          const Text('\$24,250.00', style: AppTypography.balance),

          AppSpacing.gapLG,

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: AppRadius.radiusLG,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '+12.5%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              const Icon(Icons.show_chart, color: Colors.white70, size: 42),
            ],
          ),
        ],
      ),
    );
  }
}
