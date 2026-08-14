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

  test('report snapshot compares against the immediately previous period', () {
    final transactions = <TransactionModel>[
      TransactionModel(
        id: 'previous-income',
        title: 'Previous salary',
        amount: 4000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime(2026, 7, 31, 23, 59),
      ),
      TransactionModel(
        id: 'current-income',
        title: 'Current salary',
        amount: 5000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime(2026, 8, 1),
      ),
      TransactionModel(
        id: 'current-expense',
        title: 'Current food',
        amount: 1000000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 8, 31, 23, 59),
      ),
      TransactionModel(
        id: 'next-month-expense',
        title: 'September food',
        amount: 900000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 9, 1),
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

    expect(current.income, 5000000);
    expect(current.expense, 1000000);
    expect(previous.income, 4000000);
    expect(previous.expense, 0);
    expect(snapshot.incomeChangePercent, closeTo(25, 0.0001));
    expect(snapshot.expenseChangePercent, 0);
    expect(snapshot.transactions.length, 4);
  });

  test('zero previous income does not produce an infinite comparison', () {
    final current = buildFinancialAnalytics(
      [
        TransactionModel(
          id: 'income',
          title: 'Salary',
          amount: 2500000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime(2026, 8, 10),
        ),
      ],
      DateTime(2026, 8),
      DateTime(2026, 9),
    );
    final previous = buildFinancialAnalytics(
      const <TransactionModel>[],
      DateTime(2026, 7),
      DateTime(2026, 8),
    );

    final snapshot = ReportSnapshot(
      current: current,
      previous: previous,
      transactions: const <TransactionModel>[],
    );

    expect(snapshot.incomeChangePercent, 0);
    expect(snapshot.expenseChangePercent, 0);
  });
}
