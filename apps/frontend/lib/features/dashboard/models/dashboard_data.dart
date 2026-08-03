import 'budget_item.dart';
import 'dashboard_summary.dart';
import 'transaction_model.dart';

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.budgetItems,
    required this.transactions,
  });

  final DashboardSummary summary;
  final List<BudgetItem> budgetItems;
  final List<TransactionModel> transactions;

  DashboardData copyWith({
    DashboardSummary? summary,
    List<BudgetItem>? budgetItems,
    List<TransactionModel>? transactions,
  }) {
    return DashboardData(
      summary: summary ?? this.summary,
      budgetItems: budgetItems ?? this.budgetItems,
      transactions: transactions ?? this.transactions,
    );
  }
}
