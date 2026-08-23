import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../goals/controllers/supabase_goals_controller.dart' as goals;
import '../../wallet/controllers/wallet_controller.dart';

final financialGoalsProvider = goals.financialGoalsProvider;
final totalGoalSavedProvider = goals.totalGoalSavedProvider;
final totalGoalTargetProvider = goals.totalGoalTargetProvider;
final totalGoalRemainingProvider = goals.totalGoalRemainingProvider;
final completedGoalsProvider = goals.completedGoalsProvider;

/// Local installment records are not a financial source of truth.
/// They must never change net worth, available cash, or dashboard math.
class InstallmentSnapshot {
  const InstallmentSnapshot({
    required this.id,
    required this.title,
    required this.monthlyAmount,
    required this.remaining,
    required this.dueInDays,
    required this.isPaid,
  });

  final String id;
  final String title;
  final double monthlyAmount;
  final double remaining;
  final int dueInDays;
  final bool isPaid;
}

final installmentsProvider = Provider<List<InstallmentSnapshot>>((ref) {
  return const [];
});

final totalInstallmentRemainingProvider = Provider<double>((ref) => 0);
final installmentDueThisPeriodProvider = Provider<double>((ref) => 0);
final activeInstallmentsProvider = Provider<List<InstallmentSnapshot>>((ref) {
  return const [];
});

class FinancialStateSnapshot {
  const FinancialStateSnapshot({
    required this.totalAssets,
    required this.goalSaved,
    required this.goalTarget,
    required this.completedGoals,
    required this.liabilities,
    required this.dueThisPeriod,
  });

  final double totalAssets;
  final double goalSaved;
  final double goalTarget;
  final int completedGoals;
  final double liabilities;
  final double dueThisPeriod;

  double get walletAssets => (totalAssets - goalSaved).clamp(0.0, double.infinity);
  double get liquidAssets => walletAssets;
  double get netWorth => totalAssets - liabilities;
  double get goalProgress =>
      goalTarget <= 0 ? 0 : (goalSaved / goalTarget).clamp(0.0, 1.0);
  double get available => totalAssets - goalSaved - dueThisPeriod;
  double get debtRatio => totalAssets <= 0 ? 0 : liabilities / totalAssets;
}

final financialStateSnapshotProvider = Provider<FinancialStateSnapshot>((ref) {
  final walletAssets = ref.watch(totalWalletBalanceProvider);
  final goalSaved = ref.watch(totalGoalSavedProvider);

  return FinancialStateSnapshot(
    // Goal savings are still owned assets; they are simply no longer liquid
    // wallet balance. Local installments are excluded until a real ledger exists.
    totalAssets: walletAssets + goalSaved,
    goalSaved: goalSaved,
    goalTarget: ref.watch(totalGoalTargetProvider),
    completedGoals: ref.watch(completedGoalsProvider),
    liabilities: 0,
    dueThisPeriod: 0,
  );
});
