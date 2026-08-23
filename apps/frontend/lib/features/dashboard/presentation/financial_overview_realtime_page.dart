import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money_input.dart';
import '../../../core/widgets/context_ai_insight.dart';
import '../../../core/widgets/nexora/nexora.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../controllers/financial_overview_controller.dart';

class FinancialOverviewRealtimePage extends ConsumerWidget {
  const FinancialOverviewRealtimePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(financialStateSnapshotProvider);
    final analytics = ref.watch(financialAnalyticsProvider);

    return NexoraScaffold(
      appBar: const NexoraAppBar(title: 'Ringkasan keuangan', subtitle: 'Aset likuid dan tujuan'),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          NexoraSurface(
            variant: NexoraSurfaceVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aset likuid', style: AppTypography.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  label: spokenRupiah(snapshot.liquidAssets),
                  child: NexoraAmount(amount: snapshot.liquidAssets, role: NexoraAmountRole.hero),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Saldo wallet yang dapat digunakan. Tabungan tujuan dicatat terpisah.', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Total aset', value: snapshot.totalAssets, icon: LucideIcons.wallet, accent: AppColors.brandBright)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: _Metric(label: 'Tabungan tujuan', value: snapshot.goalSaved, icon: LucideIcons.target, accent: AppColors.ai)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Kekayaan bersih', value: snapshot.netWorth, icon: LucideIcons.scale, accent: AppColors.success)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: _Metric(label: 'Kewajiban', value: snapshot.liabilities, icon: LucideIcons.creditCard, accent: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          NexoraSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NexoraSectionHeader(title: 'Tujuan', actionLabel: '${(snapshot.goalProgress * 100).round()}%'),
                const SizedBox(height: AppSpacing.sm),
                NexoraProgress(value: snapshot.goalProgress),
                const SizedBox(height: AppSpacing.xs),
                Text('${rupiah(snapshot.goalSaved)} dari ${rupiah(snapshot.goalTarget)} target', style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const NexoraBanner(
            title: 'Cicilan',
            message: 'Kewajiban cicilan belum tercatat di buku besar, jadi tidak memengaruhi kekayaan bersih.',
            tone: NexoraBannerTone.info,
          ),
          const SizedBox(height: AppSpacing.sm),
          NexoraSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NexoraSectionHeader(title: 'Arus kas'),
                const SizedBox(height: AppSpacing.xs),
                Text('Pemasukan ${rupiah(analytics.income)} • Pengeluaran ${rupiah(analytics.expense)}', style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ContextAIInsight(
            title: 'Analisis',
            message: _summary(snapshot: snapshot, cashflow: analytics.netCashflow),
          ),
        ],
      ),
    );
  }

  static String _summary({required FinancialStateSnapshot snapshot, required double cashflow}) {
    if (snapshot.liquidAssets == 0) {
      return 'Belum ada saldo wallet yang terbaca. Tambahkan wallet agar ringkasan keuangan bisa dihitung.';
    }
    if (cashflow < 0) {
      return 'Arus kas periode ini negatif. Pengeluaran lebih besar daripada pemasukan yang tercatat.';
    }
    return 'Aset likuid berasal dari saldo wallet. Tabungan tujuan tetap dihitung sebagai aset, tetapi tidak likuid.';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon, required this.accent});
  final String label;
  final double value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return NexoraSurface(
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption),
          Semantics(
            label: spokenRupiah(value),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(rupiah(value), style: AppTypography.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}
