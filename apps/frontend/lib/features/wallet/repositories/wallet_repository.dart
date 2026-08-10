import '../../../core/theme/app_colors.dart';
import '../models/wallet_model.dart';

abstract interface class WalletRepository {
  Future<List<WalletModel>> getWallets();

  Future<WalletModel> getWallet(String id);

  Future<WalletModel> createWallet(WalletModel wallet);

  Future<WalletModel> updateWallet(WalletModel wallet);

  Future<void> deleteWallet(String id);
}

class MockWalletRepository implements WalletRepository {
  MockWalletRepository();

  List<WalletModel> _wallets = <WalletModel>[
    WalletModel(
      id: 'wallet_bca',
      name: 'BCA Utama',
      bankName: 'Bank Central Asia',
      accountNumber: '1234567890',
      balance: 12500000,
      type: WalletType.bank,
      color: AppColors.primary,
      isPrimary: true,
    ),
    WalletModel(
      id: 'wallet_mandiri',
      name: 'Mandiri',
      bankName: 'Bank Mandiri',
      accountNumber: '9876543210',
      balance: 8750000,
      type: WalletType.bank,
      color: AppColors.info,
    ),
    WalletModel(
      id: 'wallet_gopay',
      name: 'GoPay',
      bankName: 'GoPay',
      accountNumber: '081234567890',
      balance: 1250000,
      type: WalletType.ewallet,
      color: AppColors.success,
    ),
    WalletModel(
      id: 'wallet_cash',
      name: 'Cash',
      bankName: 'Tunai',
      accountNumber: 'CASH',
      balance: 600000,
      type: WalletType.cash,
      color: AppColors.warning,
    ),
  ];

  @override
  Future<List<WalletModel>> getWallets() async {
    await _simulateDelay();
    return List<WalletModel>.unmodifiable(_wallets);
  }

  @override
  Future<WalletModel> getWallet(String id) async {
    await _simulateDelay();
    return _findWallet(id);
  }

  @override
  Future<WalletModel> createWallet(WalletModel wallet) async {
    await _simulateDelay();

    if (_wallets.any((item) => item.id == wallet.id)) {
      throw StateError('Wallet dengan id "${wallet.id}" sudah ada.');
    }

    // Jangan pernah mutate list yang mungkin berasal dari state/UI.
    // Buat salinan growable sebelum menambahkan item.
    _wallets = List<WalletModel>.from(_wallets)..add(wallet);

    return wallet;
  }

  @override
  Future<WalletModel> updateWallet(WalletModel wallet) async {
    await _simulateDelay();

    final index = _wallets.indexWhere((item) => item.id == wallet.id);

    if (index == -1) {
      throw StateError('Wallet dengan id "${wallet.id}" tidak ditemukan.');
    }

    final updated = List<WalletModel>.from(_wallets);
    updated[index] = wallet;
    _wallets = updated;

    return wallet;
  }

  @override
  Future<void> deleteWallet(String id) async {
    await _simulateDelay();

    final index = _wallets.indexWhere((item) => item.id == id);

    if (index == -1) {
      throw StateError('Wallet dengan id "$id" tidak ditemukan.');
    }

    final updated = List<WalletModel>.from(_wallets)..removeAt(index);
    _wallets = updated;
  }

  WalletModel _findWallet(String id) {
    for (final wallet in _wallets) {
      if (wallet.id == id) {
        return wallet;
      }
    }

    throw StateError('Wallet dengan id "$id" tidak ditemukan.');
  }

  Future<void> _simulateDelay() {
    return Future<void>.delayed(const Duration(milliseconds: 450));
  }
}
