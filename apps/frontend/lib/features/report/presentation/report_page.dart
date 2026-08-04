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
        ],
      ),
    );
  }
}

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
