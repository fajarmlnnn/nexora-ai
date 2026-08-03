import '../models/dashboard_summary.dart';
import '../models/transaction_model.dart';
import '../models/budget_item.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dashboard_data.dart';
import '../models/ai_insight.dart';

class DashboardRepository {
  const DashboardRepository();

  Future<DashboardSummary> getDashboardSummary() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return DashboardSummary(
      totalBalance: 24250,
      monthlyIncome: 8240,
      monthlyExpense: 2150,
      monthlyBudget: 5000,
      budgetUsed: 3380,
      currency: 'USD',
      lastUpdated: DateTime.now(),
    );
  }

  Future<List<TransactionModel>> getRecentTransactions() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      TransactionModel(
        id: '1',
        title: 'Salary',
        amount: 3250,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime.now(),
      ),
      TransactionModel(
        id: '2',
        title: 'McDonald\'s',
        amount: 24.5,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime.now(),
      ),
      TransactionModel(
        id: '3',
        title: 'Uniqlo',
        amount: 89,
        type: TransactionType.expense,
        category: TransactionCategory.shopping,
        date: DateTime.now(),
      ),
    ];
  }

  Future<List<BudgetItem>> getBudgetItems() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      BudgetItem(
        id: 'food',
        name: 'Food',
        spent: 680,
        limit: 900,
        color: AppColors.success,
      ),
      BudgetItem(
        id: 'transport',
        name: 'Transport',
        spent: 420,
        limit: 600,
        color: AppColors.warning,
      ),
      BudgetItem(
        id: 'shopping',
        name: 'Shopping',
        spent: 930,
        limit: 1000,
        color: AppColors.danger,
      ),
    ];
  }

  Future<DashboardData> getDashboardData() async {
    final summary = await getDashboardSummary();

    final budgets = await getBudgetItems();

    final transactions = await getRecentTransactions();

    return DashboardData(
      summary: summary,
      budgetItems: budgets,
      transactions: transactions,
    );
  }

  Future<AIInsight> getAIInsight() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const AIInsight(
      title: 'Nexora AI Insight',
      message:
          'Great job! Your spending decreased by 12% compared to last month.',
      level: InsightLevel.positive,
    );
  }
}
