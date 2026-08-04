import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class InstallmentPage extends StatelessWidget {
  const InstallmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: ListView(
        padding: AppSpacing.screen,
        children: const [
          Text('Cicilan & Tagihan', style: AppTypography.heading1),
          SizedBox(height: 20),
          _InstallmentCard(
            title: 'SPayLater',
            amount: 'Rp 250.000 / bulan',
            status: '3 hari lagi',
            remaining: 'Sisa Rp 1.250.000',
            color: AppColors.danger,
          ),
          _InstallmentCard(
            title: 'Kredit Motor',
            amount: 'Rp 850.000 / bulan',
            status: '11 hari lagi',
            remaining: 'Sisa Rp 6.800.000',
            color: AppColors.warning,
          ),
          _InstallmentCard(
            title: 'Kredit Laptop',
            amount: 'Rp 600.000 / bulan',
            status: 'Sudah dibayar',
            remaining: 'Sisa Rp 1.200.000',
            color: AppColors.success,
          ),
          SizedBox(height: 20),
          EmptyStateCard(
            icon: LucideIcons.calendarPlus,
            title: 'Tambah cicilan',
            message: 'Pantau jatuh tempo agar tidak terkena denda.',
            action: '+ Cicilan',
          ),
        ],
      ),
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    required this.title,
    required this.amount,
    required this.status,
    required this.remaining,
    required this.color,
  });

  final String title;
  final String amount;
  final String status;
  final String remaining;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PremiumCard(
        borderRadius: AppRadius.radiusXL,
        child: Row(
          children: [
            PremiumIconBadge(icon: LucideIcons.creditCard, color: color),
            AppSpacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLarge),
                  Text(amount, style: AppTypography.bodySmall),
                  Text(remaining, style: AppTypography.caption),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: AppRadius.radiusLG,
                border: Border.all(color: color.withValues(alpha: .45)),
              ),
              child: Text(status, style: AppTypography.caption.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
