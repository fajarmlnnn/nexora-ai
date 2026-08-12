import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/supabase/supabase_auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authRepository = SupabaseAuthRepository();
  bool _loggingOut = false;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Sesi Nexora di perangkat ini akan diakhiri.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);

    try {
      await _authRepository.logout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout gagal: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepository.currentUser;
    final displayName = user?.userMetadata?['name']?.toString();
    final email = user?.email ?? 'Akun Nexora';
    final title = displayName?.trim().isNotEmpty == true
        ? displayName!
        : 'Nexora User';

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
        padding: AppSpacing.screen.copyWith(
          bottom: AppSpacing.bottomNav(context),
        ),
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
                      Text(title, style: AppTypography.heading3),
                      Text(email, style: AppTypography.bodySmall),
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
            onPressed: _loggingOut ? null : _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
            ),
            icon: _loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.logOut),
            label: Text(_loggingOut ? 'Logging out...' : 'Logout'),
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
