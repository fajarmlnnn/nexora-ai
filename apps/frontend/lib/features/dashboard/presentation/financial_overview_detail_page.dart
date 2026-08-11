import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/context_ai_insight.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../controllers/financial_overview_controller.dart';
import '../models/transaction_model.dart';

class FinancialOverviewDetailPage extends ConsumerWidget {
  const FinancialOverviewDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financial = ref.watch(financialStateSnapshotProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final goals = ref.watch(financialGoalsProvider);
    final installments = ref.watch(activeInstallmentsProvider);

    return PremiumScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
              ),
              const SizedBox(width: 4),
              Expanded(child: Text('Financial Overview', style: AppTypography.heading2)),
            ],
          ),
          const SizedBox(height: 10),
          NCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF171525), Color(0xFF12121C), Color(0xFF0D0E15)],
            ),
            showBorder: true,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net Worth', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rupiah(financial.netWorth),
                    style: AppTypography.heading1.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total aset dikurangi seluruh kewajiban yang masih tercatat.',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MetricCard(label: 'Total Aset', value: rupiah(financial.totalAssets), icon: LucideIcons.wallet, accent: AppColors.primaryLight)),
              const SizedBox(width: 8),
              Expanded(child: _MetricCard(label: 'Kewajiban', value: rupiah(financial.liabilities), icon: LucideIcons.creditCard, accent: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _MetricCard(label: 'Goal Terkumpul', value: rupiah(financial.goalSaved), icon: LucideIcons.target, accent: AppColors.primaryLight)),
              const SizedBox(width: 8),
              Expanded(child: _MetricCard(label: 'Jatuh Tempo', value: rupiah(financial.dueThisPeriod), icon: LucideIcons.calendarClock, accent: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Aset Wallet',
            trailing: rupiah(financial.totalAssets),
            child: const Text(
              'Satu sumber angka untuk seluruh wallet yang terlihat. Goal tidak mengurangi Total Aset.',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Goals',
            trailing: '${(financial.goalProgress * 100).round()}%',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: financial.goalProgress,
                    minHeight: 7,
                    backgroundColor: AppColors.border.withValues(alpha: .35),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${rupiah(financial.goalSaved)} dari ${rupiah(financial.goalTarget)} target', style: AppTypography.bodySmall),
                const SizedBox(height: 4),
                Text('${financial.completedGoals} goal selesai dari ${goals.length} goal', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Cicilan & Kewajiban',
            trailing: rupiah(financial.liabilities),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total sisa kewajiban: ${rupiah(financial.liabilities)}',
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pembayaran periode ini: ${rupiah(financial.dueThisPeriod)}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                if (installments.isEmpty)
                  const Text('Tidak ada cicilan aktif.', style: AppTypography.bodySmall)
                else
                  ...installments.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.isPaid
                                        ? 'Periode ini lunas • ${rupiah(item.monthlyAmount)} / periode'
                                        : item.dueInDays > 0
                                            ? '${rupiah(item.monthlyAmount)} / periode • ${item.dueInDays} hari lagi'
                                            : '${rupiah(item.monthlyAmount)} / periode',
                                    style: AppTypography.caption.copyWith(
                                      color: item.isPaid ? AppColors.success : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  rupiah(item.remaining),
                                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text('sisa', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Available (estimasi)',
            trailing: rupiah(financial.available),
            child: Text(
              financial.available < 0
                  ? 'Nilai negatif berarti alokasi goal dan kewajiban periode ini melebihi saldo wallet. Prioritaskan kewajiban sebelum pengeluaran non-esensial.'
                  : 'Estimasi dana bebas setelah mempertimbangkan dana yang sudah dialokasikan ke goals dan kewajiban periode ini. Ini bukan saldo bank baru.',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 10),
          transactionsAsync.when(
            loading: () => const _SectionCard(title: 'Cashflow', trailing: 'Memuat…', child: ShimmerSkeleton(height: 48)),
            error: (error, _) => _SectionCard(title: 'Cashflow', trailing: '—', child: Text('Data transaksi belum tersedia: $error', style: AppTypography.bodySmall)),
            data: (transactions) {
              final income = transactions.where((item) => item.type == TransactionType.income).fold<double>(0, (sum, item) => sum + item.amount);
              final expense = transactions.where((item) => item.type == TransactionType.expense).fold<double>(0, (sum, item) => sum + item.amount);
              final netCashflow = income - expense;
              return _SectionCard(
                title: 'Cashflow',
                trailing: rupiah(netCashflow),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CashflowRow(label: 'Pemasukan', value: income),
                    _CashflowRow(label: 'Pengeluaran', value: -expense),
                    const Divider(height: 18),
                    _CashflowRow(label: 'Net Cashflow', value: netCashflow, strong: true),
                    const SizedBox(height: 6),
                    Text('${transactions.length} transaksi dalam sumber data saat ini.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          ContextAIInsight(
            title: 'Financial Overview',
            message: _aiMessage(financial),
          ),
        ],
      ),
    );
  }

  String _aiMessage(FinancialStateSnapshot financial) {
    if (financial.available < 0) {
      return 'Alokasi goals dan kewajiban periode ini melebihi saldo wallet. Prioritaskan cicilan dan kebutuhan wajib sebelum menambah pengeluaran baru.';
    }
    if (financial.completedGoals > 0) {
      return '${financial.completedGoals} goal sudah tercapai. Saat ada dana baru, Nexora bisa menyarankan mengalihkannya ke dana darurat, investasi, atau target berikutnya tanpa mengurangi Total Aset.';
    }
    if (financial.debtRatio >= .5) {
      return 'Kewajiban masih cukup besar dibanding aset wallet. Fokus menjaga cashflow positif dan hindari menambah cicilan baru untuk sementara.';
    }
    if (financial.goalProgress >= .8) {
      return 'Progress goals sudah ${(financial.goalProgress * 100).round()}%. Pertahankan kontribusi sambil tetap menyisakan ruang untuk kebutuhan rutin dan kewajiban.';
    }
    return 'Kondisi finansial sedang dipantau dari wallet, goals, cicilan, dan transaksi. Nexora akan menyesuaikan saran ketika salah satu komponen berubah.';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.accent});

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return NCard(
      showBorder: true,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: accent.withValues(alpha: .10), shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _CashflowRow extends StatelessWidget {
  const _CashflowRow({required this.label, required this.value, this.strong = false});

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final isNegative = value < 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySmall)),
          Text(
            '${isNegative ? '-' : '+'}${rupiah(value.abs())}',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: isNegative ? AppColors.danger : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.trailing, required this.child});

  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NCard(
      showBorder: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700))),
              Flexible(
                child: Text(
                  trailing,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
