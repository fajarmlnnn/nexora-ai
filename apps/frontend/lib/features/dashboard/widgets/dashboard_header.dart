import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_gradients.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});
  static const String greeting = 'Good Morning';
  static const String name = 'Fajar';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusXL,
            gradient: AppGradients.primary,
            boxShadow: AppShadows.glow,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),

        AppSpacing.hGapMD,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: AppTypography.bodySmall),
              AppSpacing.gapXXS,
              Text(name, style: AppTypography.heading2),
            ],
          ),
        ),

        Hero(
          tag: 'profile_avatar',
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusXL,
              gradient: AppGradients.primary,
              boxShadow: AppShadows.glow,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}
