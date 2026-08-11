import '../models/budget_item.dart';

class DashboardRepository {
  const DashboardRepository();

  /// Budget data is intentionally empty until the real budget persistence
  /// layer is connected. Never return seeded/demo financial numbers here.
  Future<List<BudgetItem>> getBudgetItems() async {
    return const <BudgetItem>[];
  }
}
