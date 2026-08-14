import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../goals/controllers/supabase_goals_controller.dart' as goals;
import '../../wallet/controllers/wallet_controller.dart';

// Financial Overview and the Goals screen must read the same Supabase source.
// These aliases preserve the existing overview API while removing the old
// SharedPreferences-only goal database that caused Goal to display as Rp 0.
final financialGoalsProvider = goals.financialGoalsProvider;
final totalGoalSavedProvider = goals.totalGoalSavedProvider;
final totalGoalTargetProvider = goals.totalGoalTargetProvider;
final totalGoalRemainingProvider = goals.totalGoalRemainingProvider;
final completedGoalsProvider = goals.completedGoalsProvider;

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

  bool get dueThisPeriod => !isPaid && remaining > 0;

  InstallmentSnapshot copyWith({
    String? title,
    double? monthlyAmount,
    double? remaining,
    int? dueInDays,
    bool? isPaid,
  }) {
    return InstallmentSnapshot(
      id: id,
      title: title ?? this.title,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      remaining: remaining ?? this.remaining,
      dueInDays: dueInDays ?? this.dueInDays,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'monthlyAmount': monthlyAmount,
        'remaining': remaining,
        'dueInDays': dueInDays,
        'isPaid': isPaid,
      };

  static InstallmentSnapshot fromJson(Map<String, dynamic> json) {
    return InstallmentSnapshot(
      id: json['id'] as String? ?? 'installment',
      title: json['title'] as String? ?? 'Cicilan',
      monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      dueInDays: (json['dueInDays'] as num?)?.toInt() ?? 0,
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }
}

const _installmentsStorageKey = 'nexora_installments_v1';

final installmentsProvider =
    NotifierProvider<InstallmentsController, List<InstallmentSnapshot>>(
  InstallmentsController.new,
);

class InstallmentsController extends Notifier<List<InstallmentSnapshot>> {
  @override
  List<InstallmentSnapshot> build() {
    const initial = <InstallmentSnapshot>[];
    _restore(initial);
    return initial;
  }

  Future<void> _restore(List<InstallmentSnapshot> fallback) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_installmentsStorageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = List.unmodifiable(
        decoded.map(
          (item) => InstallmentSnapshot.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
    } catch (_) {
      state = List.unmodifiable(fallback);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _installmentsStorageKey,
      jsonEncode(state.map((item) => item.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Gagal menyimpan cicilan ke penyimpanan lokal.');
    }
  }

  Future<void> replaceInstallments(
    List<InstallmentSnapshot> installments,
  ) async {
    state = List.unmodifiable(installments);
    await _persist();
  }

  Future<void> addInstallment(InstallmentSnapshot installment) async {
    state = List.unmodifiable([...state, installment]);
    await _persist();
  }

  Future<bool> payInstallment(String id, {double? amount}) async {
    final index = state.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    final installment = state[index];
    final payment = (amount ?? installment.monthlyAmount)
        .clamp(0.0, installment.remaining);
    if (payment <= 0) return false;
    final remaining = installment.remaining - payment;
    state = List.unmodifiable([
      ...state.take(index),
      installment.copyWith(
        remaining: remaining,
        isPaid: remaining <= 0,
      ),
      ...state.skip(index + 1),
    ]);
    await _persist();
    return true;
  }

  Future<void> removeInstallment(String id) async {
    state = List.unmodifiable(state.where((item) => item.id != id));
    await _persist();
  }
}

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

final activeInstallmentsProvider = Provider<List<InstallmentSnapshot>>((ref) {
  return ref
      .watch(installmentsProvider)
      .where((item) => item.remaining > 0)
      .toList(growable: false);
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

  double get netWorth => totalAssets - liabilities;
  double get goalProgress =>
      goalTarget <= 0 ? 0 : (goalSaved / goalTarget).clamp(0.0, 1.0);
  double get available => totalAssets - goalSaved - dueThisPeriod;
  double get debtRatio => totalAssets <= 0 ? 0 : liabilities / totalAssets;
}

final financialStateSnapshotProvider = Provider<FinancialStateSnapshot>((ref) {
  return FinancialStateSnapshot(
    totalAssets: ref.watch(totalWalletBalanceProvider),
    goalSaved: ref.watch(totalGoalSavedProvider),
    goalTarget: ref.watch(totalGoalTargetProvider),
    completedGoals: ref.watch(completedGoalsProvider),
    liabilities: ref.watch(totalInstallmentRemainingProvider),
    dueThisPeriod: ref.watch(installmentDueThisPeriodProvider),
  );
});
