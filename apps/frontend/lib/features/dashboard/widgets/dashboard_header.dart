import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusXL,
            gradient: const LinearGradient(
              colors: [Color(0xFF9D7BFF), Color(0xFF7C4DFF)],
            ),
            boxShadow: AppShadows.glow,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),

        AppSpacing.hGapMD,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good Evening 👋', style: AppTypography.bodySmall),
              AppSpacing.gapXXS,
              Text('Fajar Maulana', style: AppTypography.heading2),
            ],
          ),
        ),

        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.radiusXL,
            boxShadow: AppShadows.soft,
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(Icons.notifications_rounded, color: Colors.white),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
