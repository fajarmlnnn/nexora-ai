import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/supabase/supabase_client.dart';

class FinancialGoalSnapshot {
  const FinancialGoalSnapshot({
    required this.id,
    required this.title,
    required this.type,
    required this.saved,
    required this.target,
    required this.icon,
    this.deadline,
    this.priority = 'normal',
    this.status = 'active',
  });

  final String id;
  final String title;
  final String type;
  final double saved;
  final double target;
  final IconData icon;
  final DateTime? deadline;
  final String priority;
  final String status;

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0);
  bool get isCompleted => status == 'completed' || (target > 0 && saved >= target);
  double get remaining => (target - saved).clamp(0.0, double.infinity);

  int get daysRemaining => deadline == null
      ? 0
      : deadline!.difference(DateTime.now()).inDays;

  double get suggestedMonthlyContribution {
    if (remaining <= 0) return 0;
    if (deadline == null) return remaining / 6;
    final months = (daysRemaining / 30).ceil().clamp(1, 120);
    return remaining / months;
  }

  FinancialGoalSnapshot copyWith({
    String? title,
    String? type,
    double? saved,
    double? target,
    IconData? icon,
    DateTime? deadline,
    String? priority,
    String? status,
  }) => FinancialGoalSnapshot(
        id: id,
        title: title ?? this.title,
        type: type ?? this.type,
        saved: saved ?? this.saved,
        target: target ?? this.target,
        icon: icon ?? this.icon,
        deadline: deadline ?? this.deadline,
        priority: priority ?? this.priority,
        status: status ?? this.status,
      );

  static FinancialGoalSnapshot fromMap(Map<String, dynamic> row) {
    final type = (row['type'] as String? ?? 'saving').toLowerCase();
    final title = row['name'] as String? ?? '';
    final id = row['id'] as String? ?? '';
    final target = (row['target_amount'] as num?)?.toDouble() ?? 0;
    final saved = (row['saved_amount'] as num?)?.toDouble() ?? 0;
    return FinancialGoalSnapshot(
      id: id,
      title: title,
      type: _displayType(type),
      saved: saved,
      target: target,
      icon: _iconForType(type),
      deadline: row['deadline'] == null ? null : DateTime.tryParse(row['deadline'] as String),
      priority: row['priority'] as String? ?? 'normal',
      status: row['status'] as String? ?? 'active',
    );
  }
}

String _dbType(String type) {
  switch (type.toLowerCase()) {
    case 'wishlist':
      return 'wishlist';
    case 'debt':
      return 'debt';
    default:
      return 'saving';
  }
}

String _displayType(String type) {
  switch (type.toLowerCase()) {
    case 'wishlist':
      return 'Wishlist';
    case 'debt':
      return 'Debt';
    default:
      return 'Saving';
  }
}

IconData _iconForType(String type) {
  switch (type.toLowerCase()) {
    case 'wishlist':
      return LucideIcons.shoppingBag;
    case 'debt':
      return LucideIcons.creditCard;
    default:
      return LucideIcons.target;
  }
}

final financialGoalsProvider =
    NotifierProvider<SupabaseFinancialGoalsController, List<FinancialGoalSnapshot>>(
  SupabaseFinancialGoalsController.new,
);

class SupabaseFinancialGoalsController extends Notifier<List<FinancialGoalSnapshot>> {
  @override
  List<FinancialGoalSnapshot> build() {
    _load();
    return const [];
  }

  String get _userId {
    final user = NexoraSupabase.client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum terautentikasi.');
    }
    return user.id;
  }

  Future<void> _load() async {
    if (!NexoraSupabase.isInitialized) return;
    try {
      final rows = await NexoraSupabase.client
          .from('goals')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      state = List.unmodifiable(
        (rows as List)
            .map((row) => FinancialGoalSnapshot.fromMap(Map<String, dynamic>.from(row as Map)))
            .where((goal) => goal.id.isNotEmpty && goal.title.isNotEmpty)
            .toList(growable: false),
      );
    } catch (_) {
      // Keep the previous in-memory state on transient refresh failures.
    }
  }

  Future<void> reload() => _load();

  Future<void> addGoal(FinancialGoalSnapshot goal) async {
    if (goal.title.trim().isEmpty || goal.target <= 0 || goal.saved < 0) {
      throw StateError('Data goal tidak valid.');
    }

    // RLS requires the inserted owner to match auth.uid(). Explicitly send
    // the authenticated user's UUID instead of relying on a database default.
    // This is the same ownership contract already used by transactions.
    final userId = _userId;
    final row = await NexoraSupabase.client
        .from('goals')
        .insert({
          'user_id': userId,
          'name': goal.title.trim(),
          'type': _dbType(goal.type),
          'target_amount': goal.target,
          'saved_amount': 0,
          'deadline': goal.deadline?.toIso8601String().split('T').first,
          'priority': goal.priority,
          'status': 'active',
        })
        .select()
        .single();

    var created = FinancialGoalSnapshot.fromMap(Map<String, dynamic>.from(row));

    try {
      if (goal.saved > 0) {
        final result = await NexoraSupabase.client.rpc(
          'nexora_contribute_to_goal',
          params: {
            'p_goal_id': created.id,
            'p_amount': goal.saved,
            'p_note': 'Saldo awal goal',
          },
        );
        created = FinancialGoalSnapshot.fromMap(
          Map<String, dynamic>.from(result as Map),
        );
      }
    } catch (_) {
      await NexoraSupabase.client
          .from('goals')
          .delete()
          .eq('id', created.id)
          .eq('user_id', userId);
      rethrow;
    }

    state = List.unmodifiable([created, ...state]);
  }

  Future<bool> contribute(String id, double amount, {String? note}) async {
    if (amount <= 0 || !amount.isFinite) return false;
    try {
      final result = await NexoraSupabase.client.rpc(
        'nexora_contribute_to_goal',
        params: {
          'p_goal_id': id,
          'p_amount': amount,
          'p_note': note,
        },
      );
      final updated = FinancialGoalSnapshot.fromMap(
        Map<String, dynamic>.from(result as Map),
      );
      _replace(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateGoal(
    String id, {
    double? target,
    String? title,
    DateTime? deadline,
    String? priority,
    String? status,
  }) async {
    if (target != null && target <= 0) return false;
    final payload = <String, dynamic>{};
    if (target != null) payload['target_amount'] = target;
    if (title != null && title.trim().isNotEmpty) payload['name'] = title.trim();
    if (deadline != null) payload['deadline'] = deadline.toIso8601String().split('T').first;
    if (priority != null) payload['priority'] = priority;
    if (status != null) payload['status'] = status;
    if (payload.isEmpty) return false;

    try {
      final row = await NexoraSupabase.client
          .from('goals')
          .update(payload)
          .eq('id', id)
          .eq('user_id', _userId)
          .select()
          .single();
      _replace(FinancialGoalSnapshot.fromMap(Map<String, dynamic>.from(row)));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pauseGoal(String id) => updateGoal(id, status: 'paused');
  Future<bool> resumeGoal(String id) => updateGoal(id, status: 'active');

  Future<void> removeGoal(String id) async {
    await NexoraSupabase.client
        .from('goals')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
    state = List.unmodifiable(state.where((goal) => goal.id != id));
  }

  void _replace(FinancialGoalSnapshot updated) {
    final index = state.indexWhere((goal) => goal.id == updated.id);
    if (index < 0) {
      state = List.unmodifiable([updated, ...state]);
      return;
    }
    final next = [...state];
    next[index] = updated;
    state = List.unmodifiable(next);
  }
}

final totalGoalSavedProvider = Provider<double>((ref) => ref.watch(financialGoalsProvider).fold<double>(0, (sum, goal) => sum + goal.saved));
final totalGoalTargetProvider = Provider<double>((ref) => ref.watch(financialGoalsProvider).fold<double>(0, (sum, goal) => sum + goal.target));
final totalGoalRemainingProvider = Provider<double>((ref) => ref.watch(financialGoalsProvider).fold<double>(0, (sum, goal) => sum + goal.remaining));
final completedGoalsProvider = Provider<int>((ref) => ref.watch(financialGoalsProvider).where((goal) => goal.isCompleted).length);
