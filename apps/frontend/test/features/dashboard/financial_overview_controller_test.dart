import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/controllers/financial_overview_controller.dart';

void main() {
  group('FinancialStateSnapshot', () {
    test('calculates net worth and available funds from its inputs', () {
      const snapshot = FinancialStateSnapshot(
        totalAssets: 10_000_000,
        goalSaved: 2_500_000,
        goalTarget: 5_000_000,
        completedGoals: 1,
        liabilities: 1_500_000,
        dueThisPeriod: 500_000,
      );

      expect(snapshot.netWorth, 8_500_000);
      expect(snapshot.available, 7_000_000);
      expect(snapshot.goalProgress, closeTo(.5, .0001));
      expect(snapshot.debtRatio, closeTo(.15, .0001));
    });

    test('clamps goal progress to a safe range', () {
      const snapshot = FinancialStateSnapshot(
        totalAssets: 1_000_000,
        goalSaved: 2_000_000,
        goalTarget: 1_000_000,
        completedGoals: 1,
        liabilities: 0,
        dueThisPeriod: 0,
      );

      expect(snapshot.goalProgress, 1);
    });

    test('returns zero progress when there is no goal target', () {
      const snapshot = FinancialStateSnapshot(
        totalAssets: 1_000_000,
        goalSaved: 0,
        goalTarget: 0,
        completedGoals: 0,
        liabilities: 0,
        dueThisPeriod: 0,
      );

      expect(snapshot.goalProgress, 0);
    });

    test('available can become negative when allocations exceed assets', () {
      const snapshot = FinancialStateSnapshot(
        totalAssets: 1_000_000,
        goalSaved: 800_000,
        goalTarget: 1_000_000,
        completedGoals: 0,
        liabilities: 500_000,
        dueThisPeriod: 400_000,
      );

      expect(snapshot.available, -200_000);
      expect(snapshot.netWorth, 500_000);
    });

    test('does not produce an invalid debt ratio for zero assets', () {
      const snapshot = FinancialStateSnapshot(
        totalAssets: 0,
        goalSaved: 0,
        goalTarget: 1_000_000,
        completedGoals: 0,
        liabilities: 500_000,
        dueThisPeriod: 100_000,
      );

      expect(snapshot.debtRatio, 0);
      expect(snapshot.available, -100_000);
    });
  });
}
