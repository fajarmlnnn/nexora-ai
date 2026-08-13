import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';
import 'package:frontend/features/finance/state/financial_analytics_provider.dart';

TransactionModel _transaction({
  required String id,
  required TransactionType type,
  required double amount,
  required DateTime date,
  TransactionCategory category = TransactionCategory.other,
}) {
  return TransactionModel(
    id: id,
    title: id,
    amount: amount,
    type: type,
    category: category,
    date: date,
    walletId: type == TransactionType.transfer ? null : 'wallet-1',
    sourceAccount: type == TransactionType.transfer ? 'wallet-1' : null,
    destinationAccount: type == TransactionType.transfer ? 'wallet-2' : null,
  );
}

void main() {
  final start = DateTime(2026, 8);
  final end = DateTime(2026, 9);

  test('calculates income, expense, net cashflow and savings rate', () {
    final snapshot = buildFinancialAnalytics(
      [
        _transaction(
          id: 'income',
          type: TransactionType.income,
          amount: 5_000_000,
          date: DateTime(2026, 8, 5),
        ),
        _transaction(
          id: 'expense',
          type: TransactionType.expense,
          amount: 2_000_000,
          date: DateTime(2026, 8, 6),
          category: TransactionCategory.food,
        ),
      ],
      start,
      end,
    );

    expect(snapshot.income, 5_000_000);
    expect(snapshot.expense, 2_000_000);
    expect(snapshot.netCashflow, 3_000_000);
    expect(snapshot.savingsRate, closeTo(.6, 0.0001));
    expect(snapshot.transactionCount, 2);
    expect(snapshot.topExpenseCategory?.key, TransactionCategory.food);
    expect(snapshot.topExpenseCategory?.value, 2_000_000);
  });

  test('excludes transactions outside the requested half-open range', () {
    final snapshot = buildFinancialAnalytics(
      [
        _transaction(
          id: 'before',
          type: TransactionType.income,
          amount: 1_000_000,
          date: DateTime(2026, 7, 31, 23, 59),
        ),
        _transaction(
          id: 'inside',
          type: TransactionType.income,
          amount: 2_000_000,
          date: DateTime(2026, 8, 1),
        ),
        _transaction(
          id: 'end',
          type: TransactionType.income,
          amount: 3_000_000,
          date: DateTime(2026, 9, 1),
        ),
      ],
      start,
      end,
    );

    expect(snapshot.income, 2_000_000);
    expect(snapshot.transactionCount, 1);
  });

  test('keeps internal transfers out of income and expense', () {
    final snapshot = buildFinancialAnalytics(
      [
        _transaction(
          id: 'transfer',
          type: TransactionType.transfer,
          amount: 750_000,
          date: DateTime(2026, 8, 10),
        ),
      ],
      start,
      end,
    );

    expect(snapshot.income, 0);
    expect(snapshot.expense, 0);
    expect(snapshot.netCashflow, 0);
    expect(snapshot.transferIn, 750_000);
    expect(snapshot.transferOut, 750_000);
    expect(snapshot.transferNet, 0);
  });

  test('handles zero income without producing an invalid savings rate', () {
    final snapshot = buildFinancialAnalytics(
      [
        _transaction(
          id: 'expense',
          type: TransactionType.expense,
          amount: 250_000,
          date: DateTime(2026, 8, 12),
        ),
      ],
      start,
      end,
    );

    expect(snapshot.savingsRate, 0);
    expect(snapshot.netCashflow, -250_000);
  });
}
