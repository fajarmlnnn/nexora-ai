import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/controllers/financial_overview_controller.dart';

void main() {
  test('local installments never change net worth', () {
    const snapshot = FinancialStateSnapshot(
      totalAssets: 10_000_000,
      goalSaved: 2_000_000,
      goalTarget: 5_000_000,
      completedGoals: 0,
      liabilities: 0,
      dueThisPeriod: 0,
    );

    expect(snapshot.liquidAssets, 8_000_000);
    expect(snapshot.netWorth, 10_000_000);
    expect(snapshot.liabilities, 0);
  });
}
