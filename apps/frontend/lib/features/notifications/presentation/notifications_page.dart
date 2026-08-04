import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      bottomPadding: false,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          Row(
            children: [
              BackButton(color: Colors.white, onPressed: () => Navigator.pop(context)),
              Expanded(child: Text('Notifikasi', textAlign: TextAlign.center, style: AppTypography.heading2)),
              const SizedBox(width: 48),
            ],
          ),
          AppSpacing.gapLG,
          const _FilterTabs(),
          AppSpacing.gapLG,
          const SectionHeader('Hari ini'),
          const _NotificationTile(
            icon: LucideIcons.utensils,
            title: 'Budget Makan hampir habis',
            message: 'Sisa Rp 380.000 (76%)',
            time: '10:30',
            color: AppColors.danger,
          ),
          const _NotificationTile(
            icon: LucideIcons.creditCard,
            title: 'SPayLater jatuh tempo 3 hari lagi',
            message: 'Rp 250.000 - 15 Agu 2026',
            time: '09:00',
            color: AppColors.warning,
          ),
          AppSpacing.gapMD,
          const SectionHeader('Kemarin'),
          const _NotificationTile(
            icon: LucideIcons.wallet,
            title: 'Gaji masuk',
            message: 'Rp 15.000.000',
            time: '08:30',
            color: AppColors.success,
          ),
          AppSpacing.gapMD,
          const EmptyStateCard(
            icon: LucideIcons.inbox,
            title: 'Semua terbaca',
            message: 'Tidak ada notifikasi baru untuk saat ini.',
            action: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(5),
      borderRadius: AppRadius.radiusXL,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.radiusLG,
              ),
              child: Text('Semua', textAlign: TextAlign.center, style: AppTypography.labelMedium.copyWith(color: Colors.white)),
            ),
          ),
          Expanded(child: Text('Belum Dibaca', textAlign: TextAlign.center, style: AppTypography.labelMedium)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        borderRadius: AppRadius.radiusXL,
        child: Row(
          children: [
            PremiumIconBadge(icon: icon, color: color),
            AppSpacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
                  Text(message, style: AppTypography.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: AppTypography.caption),
                const SizedBox(height: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
