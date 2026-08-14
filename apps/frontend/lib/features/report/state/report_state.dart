import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_analytics_provider.dart';
import '../../finance/state/financial_transaction_store.dart';

/// A report period is half-open: [start, end).
class ReportPeriod {
  const ReportPeriod(this.start, this.end);

  final DateTime start;
  final DateTime end;

  factory ReportPeriod.currentMonth() {
    final now = DateTime.now();
    return ReportPeriod(
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    );
  }

  ReportPeriod previousMonth() => ReportPeriod(
        DateTime(start.year, start.month - 1),
        DateTime(start.year, start.month),
      );
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.current,
    required this.previous,
    required this.transactions,
  });

  final FinancialAnalyticsSnapshot current;
  final FinancialAnalyticsSnapshot previous;
  final List<TransactionModel> transactions;

  double get incomeChangePercent => _percentChange(previous.income, current.income);
  double get expenseChangePercent => _percentChange(previous.expense, current.expense);

  /// Uses the same ledger-derived income/expense values as Dashboard and Budget.
  /// Transfers are intentionally excluded from cashflow performance metrics.
  double get netCashflow => current.income - current.expense;

  static double _percentChange(double previous, double current) {
    if (previous <= 0) return 0;
    return ((current - previous) / previous) * 100;
  }
}

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return ReportPeriod.currentMonth();
});

final reportSnapshotProvider = Provider<ReportSnapshot>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final transactions = ref.watch(financialTransactionStoreProvider);
  final current = buildFinancialAnalytics(
    transactions,
    period.start,
    period.end,
  );
  final previousPeriod = period.previousMonth();
  final previous = buildFinancialAnalytics(
    transactions,
    previousPeriod.start,
    previousPeriod.end,
  );

  return ReportSnapshot(
    current: current,
    previous: previous,
    transactions: List.unmodifiable(transactions),
  );
});
