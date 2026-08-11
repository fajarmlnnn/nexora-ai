import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/models/budget_item.dart';

abstract interface class BudgetRepository {
  Future<List<BudgetItem>> getBudgets();
  Future<BudgetItem> createBudget(BudgetItem budget);
  Future<BudgetItem> updateBudget(BudgetItem budget);
  Future<void> deleteBudget(String id);
}

class LocalBudgetRepository implements BudgetRepository {
  static const String _storageKey = 'nexora.budgets.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<BudgetItem>> getBudgets() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return <BudgetItem>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Format budget lokal tidak valid.');
      }
      return decoded
          .whereType<Map>()
          .map((item) => BudgetItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (error) {
      throw StateError('Data budget lokal rusak: $error');
    }
  }

  @override
  Future<BudgetItem> createBudget(BudgetItem budget) async {
    final budgets = await getBudgets();
    if (budgets.any((item) => item.id == budget.id)) {
      throw StateError('Budget untuk kategori ini sudah ada.');
    }
    final updated = List<BudgetItem>.from(budgets)..add(budget);
    await _save(updated);
    return budget;
  }

  @override
  Future<BudgetItem> updateBudget(BudgetItem budget) async {
    final budgets = await getBudgets();
    final index = budgets.indexWhere((item) => item.id == budget.id);
    if (index == -1) throw StateError('Budget tidak ditemukan.');
    final updated = List<BudgetItem>.from(budgets)..[index] = budget;
    await _save(updated);
    return budget;
  }

  @override
  Future<void> deleteBudget(String id) async {
    final budgets = await getBudgets();
    final updated = List<BudgetItem>.from(budgets)
      ..removeWhere((item) => item.id == id);
    if (updated.length == budgets.length) throw StateError('Budget tidak ditemukan.');
    await _save(updated);
  }

  Future<void> _save(List<BudgetItem> budgets) async {
    final prefs = await _prefs;
    final saved = await prefs.setString(
      _storageKey,
      jsonEncode(budgets.map((budget) => budget.toJson()).toList(growable: false)),
    );
    if (!saved) throw StateError('Gagal menyimpan budget ke penyimpanan lokal.');
  }
}
