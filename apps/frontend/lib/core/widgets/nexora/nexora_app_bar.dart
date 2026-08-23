import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'nexora_icon_button.dart';

class NexoraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NexoraAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 64 : 76);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.xs, AppSpacing.screenGutter, AppSpacing.xs),
        child: Row(
          children: [
            if (showBack)
              NexoraIconButton(
                icon: LucideIcons.arrowLeft,
                tooltip: 'Kembali',
                onPressed: onBack ?? () => Navigator.maybePop(context),
              ),
            if (showBack) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading3),
                  if (subtitle != null)
                    Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                ],
              ),
            ),
            ...?actions,
          ],
        ),
      ),
    );
  }
}

class NexoraInlineHeader extends StatelessWidget {
  const NexoraInlineHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack) ...[
          NexoraIconButton(
            icon: LucideIcons.arrowLeft,
            tooltip: 'Kembali',
            onPressed: onBack ?? () => Navigator.maybePop(context),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.heading2),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        ...?actions,
      ],
    );
  }
}
