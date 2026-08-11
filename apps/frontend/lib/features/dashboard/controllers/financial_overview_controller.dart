import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../wallet/controllers/wallet_controller.dart';

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
  bool get isCompleted => target > 0 && saved >= target;
  double get remaining => (target - saved).clamp(0.0, double.infinity);

  FinancialGoalSnapshot copyWith({
    String? title,
    String? type,
    double? saved,
    double? target,
    IconData? icon,
  }) {
    return FinancialGoalSnapshot(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      saved: saved ?? this.saved,
      target: target ?? this.target,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'saved': saved,
        'target': target,
      };

  static FinancialGoalSnapshot fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final title = json['title'] as String? ?? '';
    final type = json['type'] as String? ?? 'Saving';
    final saved = (json['saved'] as num?)?.toDouble() ?? 0;
    final target = (json['target'] as num?)?.toDouble() ?? 0;

    if (id.isEmpty || title.trim().isEmpty || target <= 0 || saved < 0) {
      throw const FormatException('Data goal tidak valid.');
    }

    return FinancialGoalSnapshot(
      id: id,
      title: title.trim(),
      type: type,
      saved: saved > target ? target : saved,
      target: target,
      icon: _goalIcon(id),
    );
  }
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

const _goalsStorageKey = 'nexora_financial_goals_v1';
const _installmentsStorageKey = 'nexora_installments_v1';

const _legacyDemoGoalIds = {
  'emergency-fund',
  'japan-trip',
  'spaylater',
  'home-down-payment',
};

IconData _goalIcon(String id) {
  switch (id) {
    case 'emergency-fund':
      return LucideIcons.shieldCheck;
    case 'japan-trip':
      return LucideIcons.plane;
    case 'spaylater':
      return LucideIcons.creditCard;
    case 'home-down-payment':
      return LucideIcons.house;
    default:
      return LucideIcons.target;
  }
}

final financialGoalsProvider =
    NotifierProvider<FinancialGoalsController, List<FinancialGoalSnapshot>>(
  FinancialGoalsController.new,
);

class FinancialGoalsController extends Notifier<List<FinancialGoalSnapshot>> {
  @override
  List<FinancialGoalSnapshot> build() {
    _restore();
    return const [];
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_goalsStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Goal storage bukan list.');

      final loaded = <FinancialGoalSnapshot>[];
      final ids = <String>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final goal = FinancialGoalSnapshot.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (_legacyDemoGoalIds.contains(goal.id) || !ids.add(goal.id)) continue;
          loaded.add(goal);
        } catch (_) {
          // Ignore one malformed record rather than losing every valid goal.
        }
      }

      state = List.unmodifiable(loaded);

      if (loaded.length != decoded.length) {
        await _persistSnapshot(loaded);
      }
    } catch (_) {
      state = const [];
      await _persistSnapshot(const []);
    }
  }

  Future<void> _persistSnapshot(List<FinancialGoalSnapshot> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _goalsStorageKey,
      jsonEncode(goals.map((goal) => goal.toJson()).toList(growable: false)),
    );
    if (!saved) throw StateError('Gagal menyimpan goals ke penyimpanan lokal.');
  }

  Future<void> _commit(List<FinancialGoalSnapshot> next) async {
    final previous = state;
    try {
      await _persistSnapshot(next);
      state = List.unmodifiable(next);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> replaceGoals(List<FinancialGoalSnapshot> goals) async {
    final ids = <String>{};
    for (final goal in goals) {
      if (goal.id.isEmpty || goal.title.trim().isEmpty || goal.target <= 0 || goal.saved < 0 || goal.saved > goal.target || !ids.add(goal.id)) {
        throw StateError('Data goal tidak valid.');
      }
    }
    await _commit(List.unmodifiable(goals));
  }

  Future<void> addGoal(FinancialGoalSnapshot goal) async {
    if (goal.id.isEmpty || goal.title.trim().isEmpty) {
      throw StateError('Nama atau ID goal tidak valid.');
    }
    if (goal.target <= 0 || goal.saved < 0 || goal.saved > goal.target) {
      throw StateError('Target dan saldo goal tidak valid.');
    }
    if (state.any((item) => item.id == goal.id)) {
      throw StateError('Goal dengan ID tersebut sudah ada.');
    }
    await _commit([...state, goal]);
  }

  Future<bool> contribute(String id, double amount) async {
    if (amount <= 0) return false;
    final index = state.indexWhere((goal) => goal.id == id);
    if (index < 0) return false;

    final goal = state[index];
    final contribution = amount.clamp(0.0, goal.remaining);
    if (contribution <= 0) return false;

    final next = [
      ...state.take(index),
      goal.copyWith(saved: goal.saved + contribution),
      ...state.skip(index + 1),
    ];

    await _commit(next);
    return true;
  }

  Future<bool> updateGoal(String id, {double? target, String? title}) async {
    final index = state.indexWhere((goal) => goal.id == id);
    if (index < 0) return false;
    if (target != null && target <= 0) return false;
    if (title != null && title.trim().isEmpty) return false;

    final current = state[index];
    final nextTarget = target ?? current.target;
    if (current.saved > nextTarget) return false;

    final next = [
      ...state.take(index),
      current.copyWith(target: nextTarget, title: title?.trim()),
      ...state.skip(index + 1),
    ];

    await _commit(next);
    return true;
  }

  Future<void> removeGoal(String id) async {
    if (!state.any((goal) => goal.id == id)) return;
    await _commit(state.where((goal) => goal.id != id).toList(growable: false));
  }
}

final installmentsProvider =
    NotifierProvider<InstallmentsController, List<InstallmentSnapshot>>(
  InstallmentsController.new,
);

class InstallmentsController extends Notifier<List<InstallmentSnapshot>> {
  @override
  List<InstallmentSnapshot> build() {
    final initial = const <InstallmentSnapshot>[];
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
        decoded.map((item) => InstallmentSnapshot.fromJson(
              Map<String, dynamic>.from(item as Map),
            )),
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
    if (!saved) throw StateError('Gagal menyimpan cicilan ke penyimpanan lokal.');
  }

  Future<void> replaceInstallments(List<InstallmentSnapshot> installments) async {
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

final totalGoalRemainingProvider = Provider<double>((ref) {
  return ref.watch(financialGoalsProvider).fold<double>(
        0,
        (total, goal) => total + goal.remaining,
      );
});

final completedGoalsProvider = Provider<int>((ref) {
  return ref.watch(financialGoalsProvider)
      .where((goal) => goal.isCompleted)
      .length;
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

final activeInstallmentsProvider = Provider<List<InstallmentSnapshot>>((ref) {
  return ref.watch(installmentsProvider)
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
