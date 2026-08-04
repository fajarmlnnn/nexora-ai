import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/transaction_filter.dart';

class TransactionFilterChips extends StatelessWidget {
  const TransactionFilterChips({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final TransactionFilter selectedFilter;
  final ValueChanged<TransactionFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: TransactionFilter.values.map((filter) {
        final selected = selectedFilter == filter;

        return FilterChip(
          label: Text(_labelFor(filter)),
          selected: selected,
          onSelected: (_) => onSelected(filter),
          labelStyle: AppTypography.labelMedium.copyWith(
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.card,
          checkmarkColor: AppColors.white,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        );
      }).toList(),
    );
  }

  String _labelFor(TransactionFilter filter) {
    return switch (filter) {
      TransactionFilter.all => 'All',
      TransactionFilter.income => 'Income',
      TransactionFilter.expense => 'Expense',
    };
  }
}
