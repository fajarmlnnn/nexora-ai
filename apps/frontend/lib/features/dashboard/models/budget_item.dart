import 'package:flutter/material.dart';

import 'transaction_model.dart';

class BudgetItem {
  const BudgetItem({
    required this.id,
    required this.name,
    required this.spent,
    required this.limit,
    required this.color,
    this.category = TransactionCategory.other,
  });

  final String id;
  final String name;
  final double spent;
  final double limit;
  final Color color;
  /// The financial category this budget tracks. This is deliberately separate
  /// from [id], which is the database identity of the budget entity.
  final TransactionCategory category;

  double get remaining => limit - spent;

  double get progress {
    if (limit <= 0) return 0;
    return (spent / limit).clamp(0.0, 1.0);
  }

  bool get isOverBudget => spent > limit;

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category']?.toString().trim().toLowerCase();
    final category = TransactionCategory.values.firstWhere(
      (value) => value.name == rawCategory,
      orElse: () => TransactionCategory.other,
    );

    return BudgetItem(
      id: json['id'] as String,
      name: json['name'] as String,
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      limit: (json['limit'] as num).toDouble(),
      color: Color(json['color'] as int),
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'spent': spent,
      'limit': limit,
      'color': color.toARGB32(),
    };
  }

  BudgetItem copyWith({
    String? id,
    String? name,
    double? spent,
    double? limit,
    Color? color,
    TransactionCategory? category,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      spent: spent ?? this.spent,
      limit: limit ?? this.limit,
      color: color ?? this.color,
      category: category ?? this.category,
    );
  }
}
