import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/context_ai_insight.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/financial_overview_controller.dart';
import '../models/transaction_model.dart';

class FinancialOverviewDetailPage extends ConsumerWidget {
  const FinancialOverviewDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAssets = ref.watch(totalWalletBalanceProvider);
    final goalsSaved = ref.watch(totalGoalSavedProvider);
    final goalsTarget = ref.watch(totalGoalTargetProvider);
    final liabilities = ref.watch(totalInstallmentRemainingProvider);
    final dueThisPeriod = ref.watch(installmentDueThisPeriodProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    final netWorth = totalAssets - liabilities;
    final goalProgress = goalsTarget <= 0
        ? 0.0
        : (goalsSaved / goalsTarget).clamp(0.0, 1.0);
    final available = totalAssets - goalsSaved - dueThisPeriod;

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
              Expanded(
                child: Text(
                  'Financial Overview',
                  style: AppTypography.heading2,
                ),
              ),
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
                Text(
                  'Net Worth',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rupiah(netWorth),
                    style: AppTypography.heading1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total aset dikurangi seluruh kewajiban yang masih tercatat.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Total Aset',
                  value: rupiah(totalAssets),
                  icon: LucideIcons.wallet,
                  accent: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Kewajiban',
                  value: rupiah(liabilities),
                  icon: LucideIcons.creditCard,
                  accent: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Goal Terkumpul',
                  value: rupiah(goalsSaved),
                  icon: LucideIcons.target,
                  accent: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Jatuh Tempo',
                  value: rupiah(dueThisPeriod),
                  icon: LucideIcons.calendarClock,
                  accent: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Aset Wallet',
            trailing: rupiah(totalAssets),
            child: const Text(
              'Nilai ini mengikuti total saldo wallet dari shared wallet state.',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Goals',
            trailing: '${(goalProgress * 100).round()}%',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: goalProgress,
                    minHeight: 7,
                    backgroundColor: AppColors.border.withValues(alpha: .35),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${rupiah(goalsSaved)} dari ${rupiah(goalsTarget)} target',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Cicilan & Kewajiban',
            trailing: rupiah(liabilities),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jatuh tempo periode ini: ${rupiah(dueThisPeriod)}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 8),
                ...ref.watch(installmentsProvider).map(
                      (installment) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                installment.title,
                                style: AppTypography.bodySmall,
                              ),
                            ),
                            Text(
                              rupiah(installment.remaining),
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Available (estimasi)',
            trailing: rupiah(available),
            child: const Text(
              'Saldo wallet dikurangi dana yang sudah terkumpul di goals dan kewajiban periode ini. Ini bukan saldo bank dan bukan transaksi baru.',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 10),
          transactionsAsync.when(
            loading: () => const _SectionCard(
              title: 'Cashflow',
              trailing: 'Memuat…',
              child: ShimmerSkeleton(height: 48),
            ),
            error: (error, _) => _SectionCard(
              title: 'Cashflow',
              trailing: '—',
              child: Text(
                'Data transaksi belum tersedia: $error',
                style: AppTypography.bodySmall,
              ),
            ),
            data: (transactions) {
              final income = transactions
                  .where((item) => item.type == TransactionType.income)
                  .fold<double>(0, (sum, item) => sum + item.amount);
              final expense = transactions
                  .where((item) => item.type == TransactionType.expense)
                  .fold<double>(0, (sum, item) => sum + item.amount);
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
                    Text(
                      '${transactions.length} transaksi dalam sumber data saat ini.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _buildAiInsight(
            totalAssets: totalAssets,
            liabilities: liabilities,
            dueThisPeriod: dueThisPeriod,
            goalsSaved: goalsSaved,
            goalsTarget: goalsTarget,
            available: available,
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsight({
    required double totalAssets,
    required double liabilities,
    required double dueThisPeriod,
    required double goalsSaved,
    required double goalsTarget,
    required double available,
  }) {
    final debtRatio = totalAssets <= 0 ? 0.0 : liabilities / totalAssets;
    final goalProgress = goalsTarget <= 0 ? 0.0 : goalsSaved / goalsTarget;

    final String message;
    if (available < 0) {
      message =
          'Kewajiban periode ini dan alokasi goals melebihi saldo wallet yang tersedia. Prioritaskan kewajiban Rp${_compactRupiah(dueThisPeriod)} sebelum menambah pengeluaran non-esensial.';
    } else if (debtRatio >= .5) {
      message =
          'Total kewajiban masih cukup besar dibanding aset wallet. Sebaiknya hindari menambah cicilan baru dan fokus menjaga cashflow tetap positif.';
    } else if (goalProgress >= .8) {
      message =
          'Goals sudah mencapai ${(goalProgress * 100).round()}%. Pertahankan kontribusi, tetapi tetap sisakan ruang untuk kewajiban dan kebutuhan rutin.';
    } else {
      message =
          'Kondisi finansial terlihat cukup seimbang. Nexora akan terus membandingkan wallet, goals, cicilan, dan transaksi untuk memberi saran yang lebih kontekstual.';
    }

    return ContextAIInsight(
      title: 'Financial Overview',
      message: message,
    );
  }

  String _compactRupiah(double value) {
    final absolute = value.abs();
    if (absolute >= 1000000) {
      return 'Rp${(value / 1000000).toStringAsFixed(1)} jt';
    }
    if (absolute >= 1000) {
      return 'Rp${(value / 1000).toStringAsFixed(0)} rb';
    }
    return 'Rp${value.toStringAsFixed(0)}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

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
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
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
  const _SectionCard({
    required this.title,
    required this.trailing,
    required this.child,
  });

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
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  trailing,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w800,
                  ),
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
