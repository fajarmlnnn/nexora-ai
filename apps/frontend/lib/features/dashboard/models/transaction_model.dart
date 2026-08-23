enum TransactionType { income, expense, transfer }

enum TransactionCategory {
  food,
  transport,
  shopping,
  salary,
  investment,
  bills,
  entertainment,
  health,
  education,
  other,
}

extension TransactionTypeLabel on TransactionType {
  String get labelId => switch (this) {
        TransactionType.income => 'Pemasukan',
        TransactionType.expense => 'Pengeluaran',
        TransactionType.transfer => 'Transfer',
      };
}

extension TransactionCategoryLabel on TransactionCategory {
  String get labelId => switch (this) {
        TransactionCategory.food => 'Makan & Minum',
        TransactionCategory.transport => 'Transportasi',
        TransactionCategory.shopping => 'Belanja',
        TransactionCategory.salary => 'Gaji',
        TransactionCategory.investment => 'Investasi',
        TransactionCategory.bills => 'Tagihan',
        TransactionCategory.entertainment => 'Hiburan',
        TransactionCategory.health => 'Kesehatan',
        TransactionCategory.education => 'Pendidikan',
        TransactionCategory.other => 'Lainnya',
      };

  bool get isExpenseCategory =>
      this != TransactionCategory.salary && this != TransactionCategory.investment;
}

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.createdAt,
    this.note,
    this.walletId,
    this.sourceAccount,
    this.destinationAccount,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  /// Server insertion timestamp used as a deterministic tie-breaker when
  /// multiple transactions share the same user-selected occurred_at date.
  final DateTime? createdAt;
  final String? note;
  final String? walletId;
  final String? sourceAccount;
  final String? destinationAccount;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.byName(json['type'] as String),
      category: TransactionCategory.values.byName(json['category'] as String),
      date: DateTime.parse(json['date'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      note: json['note'] as String?,
      walletId: json['walletId'] as String?,
      sourceAccount: json['sourceAccount'] as String?,
      destinationAccount: json['destinationAccount'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'date': date.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'note': note,
      'walletId': walletId,
      'sourceAccount': sourceAccount,
      'destinationAccount': destinationAccount,
    };
  }

  /// Creates a copy while allowing nullable fields to be explicitly cleared.
  /// The sentinel distinguishes an omitted argument from an explicit null.
  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    Object? createdAt = _unset,
    Object? note = _unset,
    Object? walletId = _unset,
    Object? sourceAccount = _unset,
    Object? destinationAccount = _unset,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
      note: identical(note, _unset) ? this.note : note as String?,
      walletId: identical(walletId, _unset) ? this.walletId : walletId as String?,
      sourceAccount: identical(sourceAccount, _unset)
          ? this.sourceAccount
          : sourceAccount as String?,
      destinationAccount: identical(destinationAccount, _unset)
          ? this.destinationAccount
          : destinationAccount as String?,
    );
  }

  static const Object _unset = Object();
}
