import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/transaction_model.dart';
import '../models/transaction_filter.dart';
import '../widgets/transaction_empty_state.dart';
import '../widgets/transaction_filter_chips.dart';
import '../widgets/transaction_list.dart';
import '../widgets/transaction_search_field.dart';

class TransactionPage extends ConsumerStatefulWidget {
  const TransactionPage({super.key});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  TransactionFilter _filter = TransactionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Transactions', style: AppTypography.heading2),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
      ),
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          data: (transactions) {
            final filteredTransactions = _filterTransactions(transactions);

            return ListView(
              padding: AppSpacing.screen,
              children: [
                TransactionSearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                AppSpacing.gapMD,
                TransactionFilterChips(
                  selectedFilter: _filter,
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
                AppSpacing.gapXL,
                if (filteredTransactions.isEmpty)
                  const TransactionEmptyState()
                else
                  TransactionList(transactions: filteredTransactions),
              ],
            );
          },
        ),
      ),
    );
  }

  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
  ) {
    final normalizedQuery = _query.trim().toLowerCase();

    return transactions.where((transaction) {
      final matchesFilter = switch (_filter) {
        TransactionFilter.all => true,
        TransactionFilter.income => transaction.isIncome,
        TransactionFilter.expense => transaction.isExpense,
      };

      final matchesSearch = normalizedQuery.isEmpty ||
          transaction.title.toLowerCase().contains(normalizedQuery) ||
          transaction.category.name.toLowerCase().contains(normalizedQuery);

      return matchesFilter && matchesSearch;
    }).toList();
  }
}
