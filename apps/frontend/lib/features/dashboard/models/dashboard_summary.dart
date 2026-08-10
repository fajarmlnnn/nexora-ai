class DashboardSummary {
  const DashboardSummary({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyBudget,
    required this.budgetUsed,
    required this.currency,
    required this.lastUpdated,
    required this.previousBalance,
    required this.balanceChangePercent,
    required this.balanceTrendPoints,
  });

  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlyBudget;
  final double budgetUsed;
  final String currency;
  final DateTime lastUpdated;
  final double previousBalance;
  final double balanceChangePercent;
  final List<double> balanceTrendPoints;

  double get remainingBudget => monthlyBudget - budgetUsed;

  double get budgetProgress {
    if (monthlyBudget <= 0) return 0;
    return (budgetUsed / monthlyBudget).clamp(0.0, 1.0);
  }

  double get savings => monthlyIncome - monthlyExpense;

  bool get hasBalanceComparison => previousBalance > 0;

  DashboardSummary copyWith({
    double? totalBalance,
    double? monthlyIncome,
    double? monthlyExpense,
    double? monthlyBudget,
    double? budgetUsed,
    String? currency,
    DateTime? lastUpdated,
    double? previousBalance,
    double? balanceChangePercent,
    List<double>? balanceTrendPoints,
  }) {
    return DashboardSummary(
      totalBalance: totalBalance ?? this.totalBalance,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      budgetUsed: budgetUsed ?? this.budgetUsed,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      previousBalance: previousBalance ?? this.previousBalance,
      balanceChangePercent: balanceChangePercent ?? this.balanceChangePercent,
      balanceTrendPoints: balanceTrendPoints ?? this.balanceTrendPoints,
    );
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final trend = (json['balance_trend_points'] as List<dynamic>? ?? const [])
        .map((value) => (value as num).toDouble())
        .toList(growable: false);

    return DashboardSummary(
      totalBalance: (json['total_balance'] as num).toDouble(),
      monthlyIncome: (json['monthly_income'] as num).toDouble(),
      monthlyExpense: (json['monthly_expense'] as num).toDouble(),
      monthlyBudget: (json['monthly_budget'] as num).toDouble(),
      budgetUsed: (json['budget_used'] as num).toDouble(),
      currency: json['currency'] as String,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      previousBalance: (json['previous_balance'] as num?)?.toDouble() ?? 0,
      balanceChangePercent:
          (json['balance_change_percent'] as num?)?.toDouble() ?? 0,
      balanceTrendPoints: trend,
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
      'previous_balance': previousBalance,
      'balance_change_percent': balanceChangePercent,
      'balance_trend_points': balanceTrendPoints,
    };
  }
}
