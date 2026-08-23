import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';
import 'package:frontend/features/finance/repositories/transaction_repository.dart';
import 'package:frontend/features/finance/state/financial_transaction_store.dart';

class _FakeTransactionRepository implements TransactionRepository {
  final List<TransactionModel> created = [];
  final List<String> deleted = [];

  @override
  Future<List<TransactionModel>> getTransactions({
    String? walletId,
    TransactionType? type,
    TransactionCategory? category,
    String? search,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  }) async {
    return List<TransactionModel>.from(created.reversed);
  }

  @override
  Future<TransactionModel> createTransaction(
    TransactionModel transaction, {
    String? idempotencyKey,
  }) async {
    final existing = created.where((item) => item.id == transaction.id);
    if (existing.isNotEmpty) return existing.first;
    created.add(transaction);
    return transaction;
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final index = created.indexWhere((item) => item.id == transaction.id);
    if (index == -1) throw StateError('missing');
    created[index] = transaction;
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    deleted.add(id);
    created.removeWhere((item) => item.id == id);
  }
}

TransactionModel _income({
  required String id,
  required double amount,
  DateTime? date,
  String walletId = 'wallet-1',
}) {
  return TransactionModel(
    id: id,
    title: 'Gaji',
    amount: amount,
    type: TransactionType.income,
    category: TransactionCategory.salary,
    date: date ?? DateTime(2026, 8, 10),
    walletId: walletId,
  );
}

TransactionModel _expense({
  required String id,
  required double amount,
  DateTime? date,
  String walletId = 'wallet-1',
}) {
  return TransactionModel(
    id: id,
    title: 'Makan',
    amount: amount,
    type: TransactionType.expense,
    category: TransactionCategory.food,
    date: date ?? DateTime(2026, 8, 11),
    walletId: walletId,
  );
}

TransactionModel _transfer({
  required String id,
  required double amount,
}) {
  return TransactionModel(
    id: id,
    title: 'Transfer antar wallet',
    amount: amount,
    type: TransactionType.transfer,
    category: TransactionCategory.other,
    date: DateTime(2026, 8, 12),
    sourceAccount: 'wallet-1',
    destinationAccount: 'wallet-2',
  );
}

void main() {
  group('FinancialTransactionCalculations', () {
    test('transfer does not affect cashflow', () {
      final transactions = <TransactionModel>[
        _income(id: 'income', amount: 10_000),
        _expense(id: 'expense', amount: 2_500),
        _transfer(id: 'transfer', amount: 5_000),
      ];

      expect(transactions.totalIncome, 10_000);
      expect(transactions.totalExpense, 2_500);
      expect(transactions.netCashflow, 7_500);
    });

    test('monthly totals ignore transactions outside the current month', () {
      final now = DateTime.now();
      final inMonth = DateTime(now.year, now.month, 5);
      final previousMonth = DateTime(now.year, now.month - 1, 28);
      final transactions = <TransactionModel>[
        _income(id: 'current-income', amount: 1_000, date: inMonth),
        _expense(id: 'current-expense', amount: 250, date: inMonth),
        _income(id: 'old-income', amount: 9_000, date: previousMonth),
        _expense(id: 'old-expense', amount: 8_000, date: previousMonth),
      ];

      expect(transactions.monthlyIncome, 1_000);
      expect(transactions.monthlyExpense, 250);
    });
  });

  group('FinancialTransactionStore', () {
    test('rejects zero, negative and non-finite amounts before repository write', () async {
      final repository = _FakeTransactionRepository();
      final store = FinancialTransactionStore(repository);

      for (final amount in [0.0, -1.0, double.infinity, double.nan]) {
        expect(
          () => store.add(_income(id: 'invalid-${repository.created.length}', amount: amount)),
          throwsArgumentError,
        );
      }

      expect(repository.created, isEmpty);
    });

    test('rejects non-transfer transactions without a wallet', () async {
      final repository = _FakeTransactionRepository();
      final store = FinancialTransactionStore(repository);
      final transaction = _income(id: 'missing-wallet', amount: 1_000).copyWith(walletId: null);

      await expectLater(store.add(transaction), throwsArgumentError);
      expect(repository.created, isEmpty);
    });

    test('rejects transfers using the same wallet', () async {
      final repository = _FakeTransactionRepository();
      final store = FinancialTransactionStore(repository);
      final transaction = _transfer(id: 'bad-transfer', amount: 1_000).copyWith(
        destinationAccount: 'wallet-1',
      );

      await expectLater(store.add(transaction), throwsArgumentError);
      expect(repository.created, isEmpty);
    });

    test('does not duplicate an already-created transaction in local state', () async {
      final repository = _FakeTransactionRepository();
      final store = FinancialTransactionStore(repository);
      final transaction = _income(id: 'same-id', amount: 1_000);

      await store.add(transaction);
      await store.add(transaction);

      expect(repository.created, hasLength(1));
      expect(store.state, hasLength(1));
      expect(store.state.single.id, 'same-id');
    });

    test('preserves known-good state when a refresh fails', () async {
      final repository = _FailingRefreshRepository(
        initial: _income(id: 'known-good', amount: 1_000),
      );
      final store = FinancialTransactionStore(repository);

      await store.add(repository.initial);
      expect(store.state, hasLength(1));

      await store.reload();

      expect(store.hasLoadError, isTrue);
      expect(store.state, hasLength(1));
      expect(store.state.single.id, 'known-good');
    });
  });
}

class _FailingRefreshRepository extends _FakeTransactionRepository {
  _FailingRefreshRepository({required this.initial});

  final TransactionModel initial;
  bool failReads = false;

  @override
  Future<List<TransactionModel>> getTransactions({
    String? walletId,
    TransactionType? type,
    TransactionCategory? category,
    String? search,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  }) async {
    if (failReads) throw StateError('temporary network failure');
    return super.getTransactions(
      walletId: walletId,
      type: type,
      category: category,
      search: search,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<TransactionModel> createTransaction(
    TransactionModel transaction, {
    String? idempotencyKey,
  }) async {
    final result = await super.createTransaction(
      transaction,
      idempotencyKey: idempotencyKey,
    );
    failReads = true;
    return result;
  }
}
