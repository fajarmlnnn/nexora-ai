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
      totalBalance: 12500000,
      monthlyIncome: 18500000,
      monthlyExpense: 6000000,
      monthlyBudget: 5000000,
      budgetUsed: 3900000,
      currency: 'IDR',
      lastUpdated: DateTime.now(),
    );
  }

  Future<List<TransactionModel>> getRecentTransactions() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      TransactionModel(
        id: '1',
        title: 'Gaji Bulan Mei',
        amount: 15000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime.now(),
      ),
      TransactionModel(
        id: '2',
        title: 'Makan Siang',
        amount: 35000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime.now(),
      ),
      TransactionModel(
        id: '3',
        title: 'Kopi Kenangan',
        amount: 18000,
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
        name: 'Makan',
        spent: 120000,
        limit: 500000,
        color: AppColors.success,
      ),
      BudgetItem(
        id: 'transport',
        name: 'Transportasi',
        spent: 260000,
        limit: 700000,
        color: AppColors.warning,
      ),
      BudgetItem(
        id: 'shopping',
        name: 'Belanja',
        spent: 1200000,
        limit: 1500000,
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
          'Pengeluaran naik 20% dibanding bulan lalu. Nexora menyarankan kurangi makan di luar agar target dana darurat tetap aman.',
      level: InsightLevel.positive,
    );
  }
}
