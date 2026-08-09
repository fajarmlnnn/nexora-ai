import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../dashboard/models/transaction_model.dart';

class FinancialGoalSnapshot {
  const FinancialGoalSnapshot({
    required this.id,
    required this.title,
    required this.type,
    required this.saved,
    required this.target,
    required this.icon,
  });

  final String id;
  final String title;
  final String type;
  final double saved;
  final double target;
  final IconData icon;

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0);
}

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

  bool get dueThisPeriod => !isPaid;
}

final financialGoalsProvider =
    NotifierProvider<FinancialGoalsController, List<FinancialGoalSnapshot>>(
  FinancialGoalsController.new,
);

class FinancialGoalsController extends Notifier<List<FinancialGoalSnapshot>> {
  @override
  List<FinancialGoalSnapshot> build() {
    return const [
      FinancialGoalSnapshot(
        id: 'emergency-fund',
        title: 'Dana Darurat',
        type: 'Saving',
        saved: 10000000,
        target: 50000000,
        icon: LucideIcons.shieldCheck,
      ),
      FinancialGoalSnapshot(
        id: 'japan-trip',
        title: 'Liburan ke Jepang',
        type: 'Saving',
        saved: 7000000,
        target: 20000000,
        icon: LucideIcons.plane,
      ),
      FinancialGoalSnapshot(
        id: 'spaylater',
        title: 'SPayLater',
        type: 'Debt',
        saved: 1250000,
        target: 2500000,
        icon: LucideIcons.creditCard,
      ),
      FinancialGoalSnapshot(
        id: 'home-down-payment',
        title: 'DP Rumah',
        type: 'Wishlist',
        saved: 18000000,
        target: 60000000,
        icon: LucideIcons.house,
      ),
    ];
  }

  void replaceGoals(List<FinancialGoalSnapshot> goals) {
    state = List.unmodifiable(goals);
  }
}

final installmentsProvider =
    NotifierProvider<InstallmentsController, List<InstallmentSnapshot>>(
  InstallmentsController.new,
);

class InstallmentsController extends Notifier<List<InstallmentSnapshot>> {
  @override
  List<InstallmentSnapshot> build() {
    return const [
      InstallmentSnapshot(
        id: 'spaylater',
        title: 'SPayLater',
        monthlyAmount: 250000,
        remaining: 1250000,
        dueInDays: 3,
        isPaid: false,
      ),
      InstallmentSnapshot(
        id: 'motorcycle',
        title: 'Kredit Motor',
        monthlyAmount: 850000,
        remaining: 6800000,
        dueInDays: 11,
        isPaid: false,
      ),
      InstallmentSnapshot(
        id: 'laptop',
        title: 'Kredit Laptop',
        monthlyAmount: 600000,
        remaining: 1200000,
        dueInDays: 0,
        isPaid: true,
      ),
    ];
  }

  void replaceInstallments(List<InstallmentSnapshot> installments) {
    state = List.unmodifiable(installments);
  }
}

final totalGoalSavedProvider = Provider<double>((ref) {
  return ref.watch(financialGoalsProvider).fold<double>(
        0,
        (total, goal) => total + goal.saved,
      );
});

final totalGoalTargetProvider = Provider<double>((ref) {
  return ref.watch(financialGoalsProvider).fold<double>(
        0,
        (total, goal) => total + goal.target,
      );
});

final totalInstallmentRemainingProvider = Provider<double>((ref) {
  return ref.watch(installmentsProvider).fold<double>(
        0,
        (total, installment) => total + installment.remaining,
      );
});

final installmentDueThisPeriodProvider = Provider<double>((ref) {
  return ref.watch(installmentsProvider).fold<double>(
        0,
        (total, installment) =>
            total + (installment.dueThisPeriod ? installment.monthlyAmount : 0),
      );
});

final financialOverviewTransactionProvider =
    Provider.family<List<TransactionModel>, List<TransactionModel>>(
  (_, transactions) => List.unmodifiable(transactions),
);
