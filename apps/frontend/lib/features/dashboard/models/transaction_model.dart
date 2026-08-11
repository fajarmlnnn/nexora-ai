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

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
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
      'note': note,
      'walletId': walletId,
      'sourceAccount': sourceAccount,
      'destinationAccount': destinationAccount,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? note,
    String? walletId,
    String? sourceAccount,
    String? destinationAccount,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      walletId: walletId ?? this.walletId,
      sourceAccount: sourceAccount ?? this.sourceAccount,
      destinationAccount: destinationAccount ?? this.destinationAccount,
    );
  }
}
