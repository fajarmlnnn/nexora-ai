import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/financial_overview_controller.dart';

class InstallmentPage extends ConsumerWidget {
  const InstallmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installments = ref.watch(installmentsProvider);
    final remaining = ref.watch(totalInstallmentRemainingProvider);
    final dueThisPeriod = ref.watch(installmentDueThisPeriodProvider);

    return PremiumScaffold(
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          Text('Cicilan & Tagihan', style: AppTypography.heading1),
          const SizedBox(height: 6),
          Text(
            'Sisa kewajiban ${rupiah(remaining)} • Jatuh tempo periode ini ${rupiah(dueThisPeriod)}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final installment in installments)
            _InstallmentCard(installment: installment),
          const SizedBox(height: 6),
          const EmptyStateCard(
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
  const _InstallmentCard({required this.installment});

  final InstallmentSnapshot installment;

  @override
  Widget build(BuildContext context) {
    final color = installment.isPaid ? AppColors.success : AppColors.warning;
    final status = installment.isPaid
        ? 'Sudah dibayar'
        : '${installment.dueInDays} hari lagi';

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
                  Text(installment.title, style: AppTypography.labelLarge),
                  Text('${rupiah(installment.monthlyAmount)} / bulan', style: AppTypography.bodySmall),
                  Text('Sisa ${rupiah(installment.remaining)}', style: AppTypography.caption),
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
