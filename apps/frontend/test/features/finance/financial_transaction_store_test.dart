import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/models/transaction_model.dart';
import 'package:frontend/features/finance/repositories/transaction_repository.dart';
import 'package:frontend/features/finance/state/financial_transaction_store.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionModel> rows = [];

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
    var result = List<TransactionModel>.from(rows);
    if (walletId != null) {
      result = result
          .where(
            (item) =>
                item.walletId == walletId ||
                item.sourceAccount == walletId ||
                item.destinationAccount == walletId,
          )
          .toList();
    }
    return result.skip(offset).take(limit).toList();
  }

  @override
  Future<TransactionModel> createTransaction(
    TransactionModel transaction, {
    String? idempotencyKey,
  }) async {
    final existing = rows.where((item) => item.id == idempotencyKey).firstOrNull;
    if (existing != null) return existing;
    rows.insert(0, transaction);
    return transaction;
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final index = rows.indexWhere((item) => item.id == transaction.id);
    if (index < 0) throw StateError('not found');
    rows[index] = transaction;
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    rows.removeWhere((item) => item.id == id);
  }
}

TransactionModel expense({String id = 'tx-1', double amount = 100}) {
  return TransactionModel(
    id: id,
    title: 'Makan',
    amount: amount,
    type: TransactionType.expense,
    category: TransactionCategory.food,
    date: DateTime(2026, 8, 12),
    walletId: 'wallet-1',
  );
}

void main() {
  test('loads remote transactions into state', () async {
    final repository = FakeTransactionRepository()..rows.add(expense());
    final store = FinancialTransactionStore(repository);

    await store.load();

    expect(store.state, hasLength(1));
    expect(store.state.single.id, 'tx-1');
  });

  test('loads more than one page of remote transactions', () async {
    final repository = FakeTransactionRepository();
    repository.rows.addAll(
      List.generate(
        101,
        (index) => expense(id: 'tx-$index', amount: index + 1.0),
      ),
    );
    final store = FinancialTransactionStore(repository);

    await store.load();

    expect(store.state, hasLength(101));
    expect(store.state.map((item) => item.id).toSet(), hasLength(101));
  });

  test('add delegates to repository and updates state with committed row', () async {
    final repository = FakeTransactionRepository();
    final store = FinancialTransactionStore(repository);

    await store.add(expense());

    expect(repository.rows, hasLength(1));
    expect(store.state, hasLength(1));
    expect(store.state.single.amount, 100);
  });

  test('duplicate idempotent add does not duplicate state', () async {
    final repository = FakeTransactionRepository();
    final store = FinancialTransactionStore(repository);
    final transaction = expense();

    await store.add(transaction);
    await store.add(transaction);

    expect(repository.rows, hasLength(1));
    expect(store.state, hasLength(1));
  });

  test('replace and delete stay synchronized with repository', () async {
    final repository = FakeTransactionRepository()..rows.add(expense());
    final store = FinancialTransactionStore(repository);
    await store.load();

    await store.replace(expense(amount: 250));
    expect(store.state.single.amount, 250);

    await store.delete('tx-1');
    expect(store.state, isEmpty);
    expect(repository.rows, isEmpty);
  });

  test('transfer creates an internal transaction shape', () async {
    final repository = FakeTransactionRepository();
    final store = FinancialTransactionStore(repository);

    await store.transfer(
      sourceWalletId: 'wallet-a',
      destinationWalletId: 'wallet-b',
      amount: 500,
      note: 'Pindah dana',
    );

    final created = store.state.single;
    expect(created.isTransfer, isTrue);
    expect(created.sourceAccount, 'wallet-a');
    expect(created.destinationAccount, 'wallet-b');
    expect(created.amount, 500);
  });
}
