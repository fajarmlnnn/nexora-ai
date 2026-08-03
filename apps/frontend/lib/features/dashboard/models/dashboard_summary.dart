class DashboardSummary {
  const DashboardSummary({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyBudget,
    required this.budgetUsed,
    required this.currency,
    required this.lastUpdated,
  });

  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlyBudget;
  final double budgetUsed;
  final String currency;
  final DateTime lastUpdated;

  double get remainingBudget => monthlyBudget - budgetUsed;

  double get budgetProgress {
    if (monthlyBudget <= 0) return 0;
    return (budgetUsed / monthlyBudget).clamp(0.0, 1.0);
  }

  double get savings => monthlyIncome - monthlyExpense;

  DashboardSummary copyWith({
    double? totalBalance,
    double? monthlyIncome,
    double? monthlyExpense,
    double? monthlyBudget,
    double? budgetUsed,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return DashboardSummary(
      totalBalance: totalBalance ?? this.totalBalance,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      budgetUsed: budgetUsed ?? this.budgetUsed,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalBalance: (json['total_balance'] as num).toDouble(),
      monthlyIncome: (json['monthly_income'] as num).toDouble(),
      monthlyExpense: (json['monthly_expense'] as num).toDouble(),
      monthlyBudget: (json['monthly_budget'] as num).toDouble(),
      budgetUsed: (json['budget_used'] as num).toDouble(),
      currency: json['currency'] as String,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_balance': totalBalance,
      'monthly_income': monthlyIncome,
      'monthly_expense': monthlyExpense,
      'monthly_budget': monthlyBudget,
      'budget_used': budgetUsed,
      'currency': currency,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
