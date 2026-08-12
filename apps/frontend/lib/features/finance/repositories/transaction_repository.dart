import '../../dashboard/models/transaction_model.dart';

abstract interface class TransactionRepository {
  Future<List<TransactionModel>> getTransactions({
    String? walletId,
    TransactionType? type,
    TransactionCategory? category,
    String? search,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  });

  Future<TransactionModel> createTransaction(
    TransactionModel transaction, {
    String? idempotencyKey,
  });

  Future<TransactionModel> updateTransaction(TransactionModel transaction);

  Future<void> deleteTransaction(String id);
}
