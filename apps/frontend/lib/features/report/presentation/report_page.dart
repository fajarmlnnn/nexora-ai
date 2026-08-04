import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          Row(
            children: [
              Text('Report', style: AppTypography.heading1),
              const Spacer(),
              _MonthSelector(label: 'Mei 2024'),
            ],
          ),
          AppSpacing.gapLG,
          const Row(
            children: [
              Expanded(
                child: MetricPill(
                  icon: LucideIcons.arrowDownLeft,
                  label: 'Income',
                  value: 'Rp 18.500.000',
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: MetricPill(
                  icon: LucideIcons.arrowUpRight,
                  label: 'Expense',
                  value: 'Rp 6.000.000',
                  color: AppColors.danger,
                ),
              ),
            ],
          ),

          AppSpacing.gapLG,
          const Row(
            children: [
              Expanded(child: MetricPill(icon: LucideIcons.sparkles, label: 'Financial Score', value: '76 / 100', color: AppColors.primaryLight)),
              SizedBox(width: 12),
              Expanded(child: MetricPill(icon: LucideIcons.badgeCheck, label: 'Net Cashflow', value: '+Rp 12,5Jt', color: AppColors.success)),
            ],
          ),
          AppSpacing.gapLG,
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Pengeluaran per Kategori'),
                AppSpacing.gapMD,
                Row(
                  children: [
                    const Donut(
                      segments: [
                        DonutSegment(value: 25, color: AppColors.chartPurple),
                        DonutSegment(value: 20, color: AppColors.chartBlue),
                        DonutSegment(value: 30, color: AppColors.chartGreen),
                        DonutSegment(value: 25, color: AppColors.chartOrange),
                      ],
                    ),
                    AppSpacing.hGapMD,
                    const Expanded(
                      child: Column(
                        children: [
                          _Legend(label: 'Makan', value: '25%', color: AppColors.chartPurple),
                          _Legend(label: 'Transportasi', value: '20%', color: AppColors.chartBlue),
                          _Legend(label: 'Belanja', value: '30%', color: AppColors.chartGreen),
                          _Legend(label: 'Lainnya', value: '25%', color: AppColors.chartOrange),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapLG,
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Cashflow Chart'),
                AppSpacing.gapMD,
                SizedBox(
                  height: 132,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final bar in _bars)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _CashflowBar(income: bar.$1, expense: bar.$2, label: bar.$3),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),


          AppSpacing.gapLG,
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Spending Heatmap'),
                AppSpacing.gapMD,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in _heatmap)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .12 + value * .42),
                          borderRadius: AppRadius.radiusMD,
                          border: Border.all(color: AppColors.border.withValues(alpha: .35)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapLG,
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SectionHeader('Top Spending'),
                SizedBox(height: 14),
                _SpendingRow(label: 'Makan & Minuman', value: 'Rp 2.400.000', progress: .72, color: AppColors.chartPurple),
                _SpendingRow(label: 'Transportasi', value: 'Rp 890.000', progress: .42, color: AppColors.chartBlue),
                _SpendingRow(label: 'Belanja', value: 'Rp 760.000', progress: .36, color: AppColors.chartOrange),
              ],
            ),
          ),
          AppSpacing.gapLG,
          PremiumCard(
            child: Row(
              children: [
                const NexoraRobot(size: 92, waving: false),
                AppSpacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Analysis', style: AppTypography.heading3),
                      AppSpacing.gapXS,
                      Text(
                        'Pengeluaran makan naik 18%, tetapi cashflow masih sehat. Jaga batas harian Rp 120.000 minggu ini.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _heatmap = [.12, .28, .52, .18, .35, .72, .42, .22, .64, .30, .46, .88, .24, .58, .40, .18, .76, .34, .20, .50, .62];

const _bars = [
  (98.0, 42.0, '1-7'),
  (62.0, 31.0, '8-14'),
  (82.0, 46.0, '15-21'),
  (74.0, 38.0, '22-28'),
];

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: AppColors.border.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronDown, color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTypography.caption)),
          Text(value, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}


class _SpendingRow extends StatelessWidget {
  const _SpendingRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          PremiumIconBadge(icon: LucideIcons.circleDollarSign, color: color, size: 38),
          AppSpacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label, style: AppTypography.labelMedium)),
                    Text(value, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                AppSpacing.gapXS,
                AnimatedProgressBar(value: progress, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashflowBar extends StatelessWidget {
  const _CashflowBar({required this.income, required this.expense, required this.label});

  final double income;
  final double expense;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnimatedBar(height: income, color: AppColors.success),
                const SizedBox(width: 4),
                _AnimatedBar(height: expense, color: AppColors.danger),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  const _AnimatedBar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: height),
      duration: const Duration(milliseconds: 820),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          width: 10,
          height: value,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }
}
