import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/transaction_model.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  TransactionType? filter;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(recentTransactionsProvider);
    return PremiumScaffold(
      child: Padding(
        padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text('Transaksi', style: AppTypography.heading2),
              ),
              AppSpacing.gapLG,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.radiusXL,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: .45),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cari transaksi',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    Icon(
                      LucideIcons.slidersHorizontal,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapMD,
              Row(
                children: [
                  _Chip(
                    label: 'Semua',
                    selected: filter == null,
                    onTap: () => setState(() => filter = null),
                  ),
                  AppSpacing.hGapSM,
                  _Chip(
                    label: 'Pemasukan',
                    selected: filter == TransactionType.income,
                    onTap: () =>
                        setState(() => filter = TransactionType.income),
                  ),
                  AppSpacing.hGapSM,
                  _Chip(
                    label: 'Pengeluaran',
                    selected: filter == TransactionType.expense,
                    onTap: () =>
                        setState(() => filter = TransactionType.expense),
                  ),
                ],
              ),
              AppSpacing.gapLG,
              Expanded(
                child: transactions.when(
                  loading: () =>
                      const ShimmerSkeleton(height: 360),
                  error: (error, _) => Center(child: Text(error.toString())),
                  data: (items) {
                    final expanded = [...items, ..._extraTransactions()]
                        .where((item) => filter == null || item.type == filter)
                        .toList();
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: ListView(
                        key: ValueKey(filter),
                        padding: const EdgeInsets.only(bottom: 110),
                        children: [
                          _Group(
                            title: 'Hari ini',
                            items: expanded.take(4).toList(),
                          ),
                          _Group(
                            title: 'Kemarin',
                            items: expanded.skip(4).take(2).toList(),
                          ),
                          _Group(
                            title: 'Sebelumnya',
                            items: expanded.skip(6).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: selected ? AppGradients.primary : null,
        color: selected ? null : AppColors.card,
        borderRadius: AppRadius.radiusXL,
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items});
  final String title;
  final List<TransactionModel> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: AppTypography.heading3),
        ),
        for (final item in items) _TransactionTile(item: item),
        const Divider(height: 24),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});
  final TransactionModel item;
  @override
  Widget build(BuildContext context) {
    final color = item.isIncome ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .18),
              borderRadius: AppRadius.radiusLG,
            ),
            child: Icon(_icon(item.category), color: color),
          ),
          AppSpacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTypography.labelLarge),
                Text(
                  _categoryLabel(item.category),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.isIncome ? '+' : '-'}${rupiah(item.amount)}',
                style: AppTypography.labelLarge.copyWith(color: color),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(item.date),
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _icon(TransactionCategory c) => switch (c) {
  TransactionCategory.food => LucideIcons.utensils,
  TransactionCategory.transport => LucideIcons.car,
  TransactionCategory.shopping => LucideIcons.shoppingBag,
  TransactionCategory.salary => LucideIcons.wallet,
  TransactionCategory.investment => LucideIcons.chartColumn,
  TransactionCategory.bills => LucideIcons.receiptText,
  TransactionCategory.entertainment => LucideIcons.gamepad2,
  TransactionCategory.health => LucideIcons.heartPulse,
  TransactionCategory.education => LucideIcons.graduationCap,
  TransactionCategory.other => LucideIcons.circleDollarSign,
};

List<TransactionModel> _extraTransactions() => [
  TransactionModel(
    id: '4',
    title: 'Grab Bike',
    amount: 27000,
    type: TransactionType.expense,
    category: TransactionCategory.transport,
    date: DateTime.now(),
  ),
  TransactionModel(
    id: '5',
    title: 'Coffee',
    amount: 18000,
    type: TransactionType.expense,
    category: TransactionCategory.food,
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TransactionModel(
    id: '6',
    title: 'Freelance Project',
    amount: 3500000,
    type: TransactionType.income,
    category: TransactionCategory.investment,
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TransactionModel(
    id: '7',
    title: 'Monthly Groceries',
    amount: 650000,
    type: TransactionType.expense,
    category: TransactionCategory.shopping,
    date: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

String _categoryLabel(TransactionCategory category) {
  final name = category.name;
  return "${name[0].toUpperCase()}${name.substring(1)}";
}
