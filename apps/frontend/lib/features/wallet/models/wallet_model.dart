import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

export '../widgets/wallet_empty_state.dart';

enum WalletType { bank, ewallet, cash, investment }

class WalletModel {
  const WalletModel({
    required this.id,
    required this.name,
    required this.bankName,
    required this.accountNumber,
    required this.balance,
    required this.type,
    required this.color,
    this.isPrimary = false,
    this.isHidden = false,
    this.minimumBalance = 0,
  });

  final String id;
  final String name;
  final String bankName;
  final String accountNumber;
  final double balance;
  final WalletType type;
  final Color color;
  final bool isPrimary;
  final bool isHidden;
  final double minimumBalance;

  bool get hasBalance => balance > 0;
  bool get isBank => type == WalletType.bank;
  bool get isEWallet => type == WalletType.ewallet;
  bool get isCash => type == WalletType.cash;
  bool get isInvestment => type == WalletType.investment;

  bool get hasMinimumBalance => minimumBalance > 0;
  bool get isBelowMinimum => hasMinimumBalance && balance < minimumBalance;
  double get minimumBalanceGap => minimumBalance - balance;

  String get maskedAccount {
    if (accountNumber.length <= 4) {
      return accountNumber;
    }
    return "•••• ${accountNumber.substring(accountNumber.length - 4)}";
  }

  IconData get icon {
    switch (type) {
      case WalletType.bank:
        return LucideIcons.landmark;
      case WalletType.ewallet:
        return LucideIcons.walletMinimal;
      case WalletType.cash:
        return LucideIcons.banknote;
      case WalletType.investment:
        return LucideIcons.chartColumn;
    }
  }

  WalletModel copyWith({
    String? id,
    String? name,
    String? bankName,
    String? accountNumber,
    double? balance,
    WalletType? type,
    Color? color,
    bool? isPrimary,
    bool? isHidden,
    double? minimumBalance,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      color: color ?? this.color,
      isPrimary: isPrimary ?? this.isPrimary,
      isHidden: isHidden ?? this.isHidden,
      minimumBalance: minimumBalance ?? this.minimumBalance,
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json["id"] as String,
      name: json["name"] as String,
      bankName: json["bankName"] as String,
      accountNumber: json["accountNumber"] as String,
      balance: (json["balance"] as num).toDouble(),
      type: WalletType.values.byName(json["type"] as String),
      color: Color(json["color"] as int),
      isPrimary: json["isPrimary"] as bool? ?? false,
      isHidden: json["isHidden"] as bool? ?? false,
      minimumBalance: (json["minimumBalance"] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "bankName": bankName,
      "accountNumber": accountNumber,
      "balance": balance,
      "type": type.name,
      "color": color.toARGB32(),
      "isPrimary": isPrimary,
      "isHidden": isHidden,
      "minimumBalance": minimumBalance,
    };
  }
}
