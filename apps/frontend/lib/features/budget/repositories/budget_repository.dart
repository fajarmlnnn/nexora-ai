import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../dashboard/models/budget_item.dart';

abstract interface class BudgetRepository {
  Future<List<BudgetItem>> getBudgets();
  Future<BudgetItem> createBudget(BudgetItem budget);
  Future<BudgetItem> updateBudget(BudgetItem budget);
  Future<void> deleteBudget(String id);
}

/// Supabase-backed budget repository.
///
/// The database stores only the user's budget configuration. `spent` remains
/// derived from transactions by BudgetController and is never accepted from
/// the client as authoritative financial data.
class SupabaseBudgetRepository implements BudgetRepository {
  SupabaseBudgetRepository({SupabaseClient? client})
      : _client = client ?? NexoraSupabase.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum terautentikasi.');
    }
    return user.id;
  }

  @override
  Future<List<BudgetItem>> getBudgets() async {
    final rows = await _client
        .from('budgets')
        .select('id, name, budget_limit, color, category')
        .eq('user_id', _userId)
        .order('name');

    return rows
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<BudgetItem> createBudget(BudgetItem budget) async {
    _validate(budget);

    final row = await _client
        .from('budgets')
        .insert(_toPayload(budget))
        .select('id, name, budget_limit, color, category')
        .single();

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<BudgetItem> updateBudget(BudgetItem budget) async {
    _validate(budget);

    final row = await _client
        .from('budgets')
        .update({
          'name': budget.name.trim(),
          'budget_limit': budget.limit.toStringAsFixed(2),
          'color': budget.color.toARGB32(),
          'category': _normalizeCategory(budget.category),
        })
        .eq('id', budget.id.trim())
        .eq('user_id', _userId)
        .select('id, name, budget_limit, color, category')
        .maybeSingle();

    if (row == null) {
      throw StateError('Budget dengan id "${budget.id}" tidak ditemukan.');
    }
    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> deleteBudget(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('ID budget wajib diisi.');
    }

    final deleted = await _client
        .from('budgets')
        .delete()
        .eq('id', trimmed)
        .eq('user_id', _userId)
        .select('id');

    if (deleted.isEmpty) {
      throw StateError('Budget dengan id "$trimmed" tidak ditemukan.');
    }
  }

  Map<String, dynamic> _toPayload(BudgetItem budget) {
    return {
      'id': budget.id.trim(),
      'user_id': _userId,
      'name': budget.name.trim(),
      'budget_limit': budget.limit.toStringAsFixed(2),
      'color': budget.color.toARGB32(),
      'category': _normalizeCategory(budget.category),
    };
  }

  BudgetItem _fromRow(Map<String, dynamic> row) {
    final rawLimit = row['budget_limit'];
    final rawColor = row['color'];

    final limit = rawLimit is num
        ? rawLimit.toDouble()
        : double.tryParse(rawLimit?.toString() ?? '');
    final color = rawColor is num
        ? rawColor.toInt()
        : int.tryParse(rawColor?.toString() ?? '');

    if (limit == null || !limit.isFinite || limit <= 0) {
      throw StateError('Budget limit dari server tidak valid.');
    }
    if (color == null || color < 0) {
      throw StateError('Warna budget dari server tidak valid.');
    }

    return BudgetItem(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      spent: 0,
      limit: limit,
      color: Color(color),
      // Old rows are migrated with `other`; controller retains a safe legacy
      // id fallback so existing category-keyed budgets do not lose analytics.
      category: _normalizeCategory(row['category']?.toString() ?? 'other'),
    );
  }

  void _validate(BudgetItem budget) {
    if (budget.id.trim().isEmpty) {
      throw ArgumentError('ID budget wajib diisi.');
    }
    if (budget.name.trim().isEmpty) {
      throw ArgumentError('Nama budget wajib diisi.');
    }
    if (!budget.limit.isFinite || budget.limit <= 0) {
      throw ArgumentError('Limit budget harus lebih besar dari nol.');
    }
    _normalizeCategory(budget.category);
  }

  String _normalizeCategory(String category) {
    final normalized = category.trim().toLowerCase();
    const allowed = {
      'food',
      'transport',
      'shopping',
      'bills',
      'entertainment',
      'health',
      'education',
      'other',
    };
    if (!allowed.contains(normalized)) {
      throw ArgumentError('Kategori budget tidak valid.');
    }
    return normalized;
  }
}
