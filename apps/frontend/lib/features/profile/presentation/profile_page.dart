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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
        title: const Text('Keluar dari Nexora?'),
        content: const Text('Sesi di perangkat ini akan diakhiri.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      await _authRepository.logout();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout gagal: $error')));
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepository.currentUser;
    final displayName = user?.userMetadata?['name']?.toString();
    final email = user?.email ?? 'Akun Nexora';
    final title = displayName?.trim().isNotEmpty == true ? displayName! : 'Nexora User';

    final items = const [
      (LucideIcons.userRound, 'Account', 'Personal information'),
      (LucideIcons.slidersHorizontal, 'Preferences', 'Theme, currency, language'),
      (LucideIcons.cloudUpload, 'Backup', 'Sync and restore data'),
      (LucideIcons.download, 'Export Data', 'CSV and report export'),
      (LucideIcons.chartPie, 'Reports', 'Income, expense, and cashflow'),
      (LucideIcons.creditCard, 'Installments', 'Cicilan dan tagihan aktif'),
      (LucideIcons.info, 'About', 'Nexora AI version and policies'),
      (LucideIcons.circleHelp, 'Help', 'Support center'),
    ];

    return PremiumScaffold(
      child: ListView(
        padding: AppSpacing.screen.copyWith(bottom: AppSpacing.bottomNav(context)),
        children: [
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Profile', style: AppTypography.heading1.copyWith(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text('Atur pengalaman Nexora sesuai caramu.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ])),
              Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface.withValues(alpha: .8), border: Border.all(color: AppColors.border.withValues(alpha: .55))), child: const Icon(LucideIcons.settings2, size: 19)),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: AppRadius.radiusXXL,
              boxShadow: AppShadows.card,
            ),
            child: Stack(
              children: [
                Positioned(right: -35, top: -55, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .07)))),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .2))), child: const Icon(LucideIcons.userRound, color: Colors.white, size: 30)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading3.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: .78))),
                    ])),
                  ]),
                  const SizedBox(height: 18),
                  Row(children: [
                    _StatusPill(icon: LucideIcons.sparkles, label: 'Nexora Premium'),
                    const SizedBox(width: 8),
                    _StatusPill(icon: LucideIcons.shieldCheck, label: 'Protected'),
                  ]),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: _ProfileMetric(icon: LucideIcons.brainCircuit, value: 'AI', label: 'Intelligence')),
            const SizedBox(width: 10),
            Expanded(child: _ProfileMetric(icon: LucideIcons.shieldCheck, value: 'RLS', label: 'Security')),
            const SizedBox(width: 10),
            Expanded(child: _ProfileMetric(icon: LucideIcons.cloud, value: 'Sync', label: 'Cloud')),
          ]),
          const SizedBox(height: 24),
          Text('Personalize', style: AppTypography.heading3.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final item in items) _SettingTile(icon: item.$1, title: item.$2, subtitle: item.$3),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loggingOut ? null : _logout,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: BorderSide(color: AppColors.danger.withValues(alpha: .55)), backgroundColor: AppColors.danger.withValues(alpha: .04), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL)),
            icon: _loggingOut ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.logOut),
            label: Text(_loggingOut ? 'Logging out...' : 'Logout'),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .11), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: .14))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: Colors.white), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))]));
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .8), borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.border.withValues(alpha: .45))), child: Column(children: [Icon(icon, size: 18, color: AppColors.primaryLight), const SizedBox(height: 7), Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(label, style: AppTypography.overline)]));
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.card.withValues(alpha: .72), borderRadius: AppRadius.radiusXL, border: Border.all(color: AppColors.border.withValues(alpha: .4))), child: Row(children: [Container(width: 43, height: 43, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: .22), AppColors.primaryLight.withValues(alpha: .08)]), borderRadius: AppRadius.radiusLG), child: Icon(icon, color: AppColors.primaryLight, size: 20)), AppSpacing.hGapMD, Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: AppColors.textMuted))])), const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 19)]));
}
