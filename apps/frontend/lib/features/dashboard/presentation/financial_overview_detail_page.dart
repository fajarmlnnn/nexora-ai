import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/context_ai_insight.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../wallet/controllers/wallet_controller.dart';

class FinancialOverviewDetailPage extends ConsumerWidget {
  const FinancialOverviewDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAssets = ref.watch(totalWalletBalanceProvider);
    const goalsSaved = 4000000.0;
    const goalsTarget = 20000000.0;
    const liabilities = 6500000.0;
    const dueThisPeriod = 1250000.0;
    final netWorth = totalAssets - liabilities;
    final goalProgress = goalsTarget == 0
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
                  'Aset dikurangi seluruh kewajiban tercatat.',
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
              'Total aset mengikuti saldo wallet yang terlihat. Perubahan wallet akan tercermin saat state diperbarui.',
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
            title: 'Available',
            trailing: rupiah(available),
            child: const Text(
              'Estimasi awal setelah alokasi goal dan kewajiban periode ini. Angka final akan mengikuti financial engine.',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Cashflow',
            trailing: '+Rp1.250.000',
            child: const Text(
              'Income +Rp8.000.000 • Expense -Rp4.500.000 • Debt -Rp1.250.000 • Goal -Rp1.000.000',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 14),
          const ContextAIInsight(
            title: 'Financial Overview',
            message:
                'Nexora akan membaca kondisi wallet, goals, budget, transaksi, dan cicilan untuk memberikan saran finansial yang relevan.',
          ),
        ],
      ),
    );
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
