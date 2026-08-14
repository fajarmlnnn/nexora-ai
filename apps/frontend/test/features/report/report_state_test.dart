import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/dashboard/models/transaction_model.dart';
import 'package:frontend/features/finance/state/financial_analytics_provider.dart';
import 'package:frontend/features/report/state/report_state.dart';

void main() {
  test('report period is half-open and previous month is derived correctly', () {
    final period = ReportPeriod(DateTime(2026, 8), DateTime(2026, 9));
    final previous = period.previousMonth();

    expect(period.start, DateTime(2026, 8));
    expect(period.end, DateTime(2026, 9));
    expect(previous.start, DateTime(2026, 7));
    expect(previous.end, DateTime(2026, 8));
  });

  test('report snapshot net cashflow excludes internal transfers', () {
    final transactions = <TransactionModel>[
      TransactionModel(
        id: 'income',
        title: 'Salary',
        amount: 5000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime(2026, 8, 5),
      ),
      TransactionModel(
        id: 'expense',
        title: 'Food',
        amount: 750000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 8, 6),
      ),
      TransactionModel(
        id: 'transfer',
        title: 'Wallet transfer',
        amount: 1000000,
        type: TransactionType.transfer,
        category: TransactionCategory.other,
        date: DateTime(2026, 8, 7),
        sourceAccount: 'wallet-a',
        destinationAccount: 'wallet-b',
      ),
    ];

    final current = buildFinancialAnalytics(
      transactions,
      DateTime(2026, 8),
      DateTime(2026, 9),
    );
    final previous = buildFinancialAnalytics(
      transactions,
      DateTime(2026, 7),
      DateTime(2026, 8),
    );
    final snapshot = ReportSnapshot(
      current: current,
      previous: previous,
      transactions: transactions,
    );

    expect(snapshot.current.income, 5000000);
    expect(snapshot.current.expense, 750000);
    expect(snapshot.current.transferIn, 1000000);
    expect(snapshot.current.transferOut, 1000000);
    expect(snapshot.netCashflow, 4250000);
    expect(snapshot.transactions.length, 3);
  });
}
