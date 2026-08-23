import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/auth/auth_state_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/display_name.dart';
import '../../../core/widgets/nexora/nexora.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = displayNameFor(user);
    final greeting = greetingForNow(DateTime.now());

    return Row(
      children: [
        const _BrandMark(),
        AppSpacing.hGapMD,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.heading3,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Hero(
          tag: 'profile_avatar',
          child: NexoraIconButton(
            icon: LucideIcons.userRound,
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Nexora',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLG,
          gradient: AppGradients.primary,
        ),
        child: const Center(
          child: Text('N', style: AppTypography.heading3),
        ),
      ),
    );
  }
}
