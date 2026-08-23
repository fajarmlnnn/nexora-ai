import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/auth/auth_state_provider.dart';
import '../../../core/supabase/supabase_auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/display_name.dart';
import '../../../core/widgets/nexora/nexora.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _authRepository = SupabaseAuthRepository();
  bool _loggingOut = false;

  Future<void> _logout() async {
    final confirmed = await NexoraDialog.confirm(
      context,
      title: 'Keluar dari Nexora?',
      message: 'Sesi di perangkat ini akan diakhiri.',
      confirmLabel: 'Keluar',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      await _authRepository.logout();
    } catch (error) {
      if (mounted) NexoraToast.show(context, 'Gagal keluar: $error', error: true);
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final title = displayNameFor(user);
    final email = user?.email ?? 'Akun Nexora';

    return NexoraScaffold(
      appBar: const NexoraAppBar(title: 'Profil', subtitle: 'Akun dan laporan'),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          NexoraSurface(
            variant: NexoraSurfaceVariant.hero,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                  ),
                  child: const Icon(LucideIcons.userRound, color: AppColors.textPrimary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading3),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Menu', style: AppTypography.heading4),
          const SizedBox(height: AppSpacing.sm),
          _SettingTile(
            icon: LucideIcons.chartPie,
            title: 'Laporan',
            subtitle: 'Arus kas, pemasukan, dan pengeluaran',
            onTap: () => context.push('/reports'),
          ),
          _SettingTile(
            icon: LucideIcons.creditCard,
            title: 'Cicilan',
            subtitle: 'Status fitur cicilan',
            onTap: () => context.push('/installments'),
          ),
          _SettingTile(
            icon: LucideIcons.sparkles,
            title: 'Nexora AI',
            subtitle: 'Tanya gateway AI tentang ringkasan keuangan',
            onTap: () => context.push('/ai'),
          ),
          _SettingTile(
            icon: LucideIcons.bell,
            title: 'Notifikasi',
            subtitle: 'Pemberitahuan perangkat',
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: AppSpacing.md),
          NexoraButton(
            label: _loggingOut ? 'Sedang keluar...' : 'Keluar',
            variant: NexoraButtonVariant.danger,
            loading: _loggingOut,
            onPressed: _loggingOut ? null : _logout,
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: NexoraSurface(
        onTap: onTap,
        semanticLabel: title,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: .12),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Icon(icon, color: AppColors.brandBright, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
