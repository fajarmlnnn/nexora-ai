import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/card/n_card.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/ai_insight.dart';
import '../../dashboard/models/budget_item.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetItemsProvider);
    final insightAsync = ref.watch(aiInsightProvider);

    return PremiumScaffold(
      child: budgetsAsync.when(
        loading: () => ListView(
          padding: AppSpacing.screen,
          children: const [
            ShimmerSkeleton(width: 180, height: 32),
            SizedBox(height: 20),
            ShimmerSkeleton(height: 190),
            SizedBox(height: 20),
            ShimmerSkeleton(height: 330),
          ],
        ),
        error: (error, stackTrace) => Padding(
          padding: AppSpacing.screen,
          child: EmptyStateCard(
            icon: LucideIcons.triangleAlert,
            title: 'Budget belum tersedia',
            message: error.toString(),
            action: 'Coba Lagi',
          ),
        ),
        data: (items) => ListView(
          padding: AppSpacing.screen.copyWith(
            bottom: AppSpacing.bottomNav(context),
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.arrowLeft, size: 20),
                  tooltip: 'Kembali',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budget', style: AppTypography.heading1),
                      Text(
                        'Ringkasan Budget Mei 2024',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapLG,
            _BudgetOverview(items: items),
            AppSpacing.gapLG,
            _SpendingBreakdown(items: items),
            AppSpacing.gapLG,
            insightAsync.when(
              loading: () => const ShimmerSkeleton(height: 104),
              error: (_, _) => const SizedBox.shrink(),
              data: (insight) => _NexoraBudgetInsight(insight: insight),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetOverview extends StatelessWidget {
  const _BudgetOverview({required this.items});

  final List<BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    final totalLimit = items.fold<double>(0, (sum, item) => sum + item.limit);
    final totalSpent = items.fold<double>(0, (sum, item) => sum + item.spent);
    final remaining = (totalLimit - totalSpent).clamp(0.0, double.infinity);
    final progress = totalLimit <= 0
        ? 0.0
        : (totalSpent / totalLimit).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return NCard(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly Budget',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                  ),
                ),
              ),
              _StatusBadge(percentage: percentage),
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(totalLimit),
              maxLines: 1,
              softWrap: false,
              style: AppTypography.heading1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: .06),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'Terpakai',
                  value: rupiah(totalSpent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewMetric(
                  label: 'Sisa',
                  value: rupiah(remaining),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.currency.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 90
        ? AppColors.danger
        : percentage >= 75
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: AppRadius.radiusPill,
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        '$percentage% used',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _SpendingBreakdown extends StatelessWidget {
  const _SpendingBreakdown({required this.items});

  final List<BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spending Breakdown', style: AppTypography.heading3),
        const SizedBox(height: 10),
        ...visible.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _BudgetRow(item: item),
          ),
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.item});

  final BudgetItem item;

  @override
  Widget build(BuildContext context) {
    final percentage = (item.progress * 100).round();
    final accent = item.isOverBudget
        ? AppColors.danger
        : item.progress >= .85
            ? AppColors.warning
            : item.color;

    return NCard(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_icon(item.id), size: 17, color: item.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${rupiah(item.spent)} / ${rupiah(item.limit)}',
                        maxLines: 1,
                        softWrap: false,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percentage%',
                style: AppTypography.labelMedium.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: .06),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _NexoraBudgetInsight extends StatelessWidget {
  const _NexoraBudgetInsight({required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final statusIcon = switch (insight.level) {
      InsightLevel.positive => LucideIcons.badgeCheck,
      InsightLevel.warning => LucideIcons.sparkles,
      InsightLevel.critical => LucideIcons.triangleAlert,
    };

    return NCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: .06),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .14),
                    ),
                  ),
                ),
                const NexoraRobot(size: 46),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: .22),
                      ),
                    ),
                    child: Icon(
                      statusIcon,
                      size: 10,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      size: 13,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Nexora AI',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  insight.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
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

IconData _icon(String id) {
  return switch (id) {
    'food' => LucideIcons.utensils,
    'transport' => LucideIcons.car,
    'shopping' => LucideIcons.shoppingBag,
    'entertainment' => LucideIcons.gamepad2,
    'health' => LucideIcons.heartPulse,
    'education' => LucideIcons.bookOpen,
    'bills' => LucideIcons.receiptText,
    _ => LucideIcons.circleDollarSign,
  };
}
