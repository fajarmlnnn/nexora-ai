import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (LucideIcons.userRound, 'Account', 'Personal information'),
      (
        LucideIcons.slidersHorizontal,
        'Preferences',
        'Theme, currency, language',
      ),
      (LucideIcons.cloudUpload, 'Backup', 'Sync and restore data'),
      (LucideIcons.download, 'Export Data', 'CSV and report export'),
      (LucideIcons.chartPie, 'Reports', 'Income, expense, and cashflow'),
      (LucideIcons.creditCard, 'Installments', 'Cicilan dan tagihan aktif'),
      (LucideIcons.info, 'About', 'Nexora AI version and policies'),
      (LucideIcons.circleHelp, 'Help', 'Support center'),
    ];
    return PremiumScaffold(
      child: ListView(
        padding: AppSpacing.screen.copyWith(bottom: 120),
        children: [
          Text('Profile', style: AppTypography.heading1),
          AppSpacing.gapLG,
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.radiusXXL,
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: AppRadius.radiusXXL,
                  ),
                  child: const Icon(
                    LucideIcons.userRound,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                AppSpacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fajar Maulana', style: AppTypography.heading3),
                      Text('fajar@nexora.ai', style: AppTypography.bodySmall),
                      AppSpacing.gapXS,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: AppRadius.radiusLG,
                        ),
                        child: const Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapLG,
          for (final item in items)
            _SettingTile(icon: item.$1, title: item.$2, subtitle: item.$3),
          AppSpacing.gapMD,
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
            ),
            icon: const Icon(LucideIcons.logOut),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: AppRadius.radiusXL,
      border: Border.all(color: AppColors.border.withValues(alpha: .45)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .14),
            borderRadius: AppRadius.radiusLG,
          ),
          child: Icon(icon, color: AppColors.primaryLight, size: 21),
        ),
        AppSpacing.hGapMD,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLarge),
              Text(subtitle, style: AppTypography.caption),
            ],
          ),
        ),
        const Icon(LucideIcons.chevronRight, color: AppColors.textMuted),
      ],
    ),
  );
}
