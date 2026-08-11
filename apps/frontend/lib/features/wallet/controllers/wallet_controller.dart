import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/models/transaction_model.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../models/wallet_model.dart';
import '../repositories/wallet_repository.dart';

/// Repository dependency.
///
/// Wallet data is now backed by persistent local storage. The repository
/// boundary stays intact so it can later be replaced by Supabase/API storage
/// without changing the Wallet UI.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return LocalWalletRepository();
});

/// Main wallet state.
final walletProvider =
    AsyncNotifierProvider<WalletController, List<WalletModel>>(
      WalletController.new,
    );

class WalletController extends AsyncNotifier<List<WalletModel>> {
  WalletRepository get _repository => ref.read(walletRepositoryProvider);

  @override
  Future<List<WalletModel>> build() async {
    final wallets = await _repository.getWallets();
    final transactions = ref.watch(financialTransactionStoreProvider);
    return _applyTransactions(wallets, transactions);
  }

  /// Refresh wallet tanpa sengaja membuang data lama dari UI.
  Future<void> refreshWallets() async {
    final previous = state;
    final result = await AsyncValue.guard<List<WalletModel>>(() async {
      final wallets = await _repository.getWallets();
      final transactions = ref.read(financialTransactionStoreProvider);
      return _applyTransactions(wallets, transactions);
    });

    if (result.hasError && previous.hasValue) {
      state = result.copyWithPrevious(previous);
      return;
    }

    state = result;
  }

  /// Tambahkan wallet baru.
  Future<bool> addWallet(WalletModel wallet) async {
    try {
      await _repository.createWallet(wallet);
      await _reload();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<WalletModel>>.error(
        error,
        stackTrace,
      ).copyWithPrevious(state);
      return false;
    }
  }

  /// Update wallet.
  Future<bool> updateWallet(WalletModel wallet) async {
    try {
      await _repository.updateWallet(wallet);
      await _reload();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<WalletModel>>.error(
        error,
        stackTrace,
      ).copyWithPrevious(state);
      return false;
    }
  }

  /// Hapus wallet.
  Future<bool> deleteWallet(String id) async {
    try {
      await _repository.deleteWallet(id);
      await _reload();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<WalletModel>>.error(
        error,
        stackTrace,
      ).copyWithPrevious(state);
      return false;
    }
  }

  /// Menyembunyikan atau menampilkan wallet.
  Future<bool> setWalletVisibility(String id, {required bool hidden}) async {
    final wallet = _findWallet(id);
    if (wallet == null) return false;
    return updateWallet(wallet.copyWith(isHidden: hidden));
  }

  /// Menjadikan wallet tertentu sebagai wallet utama.
  Future<bool> setPrimaryWallet(String id) async {
    final wallets = state.valueOrNull;
    if (wallets == null || wallets.isEmpty) return false;

    final target = _findWallet(id);
    if (target == null) return false;

    try {
      for (final wallet in wallets) {
        final shouldBePrimary = wallet.id == id;
        if (wallet.isPrimary != shouldBePrimary) {
          await _repository.updateWallet(
            wallet.copyWith(isPrimary: shouldBePrimary),
          );
        }
      }
      await _reload();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<WalletModel>>.error(
        error,
        stackTrace,
      ).copyWithPrevious(state);
      return false;
    }
  }

  WalletModel? _findWallet(String id) {
    final wallets = state.valueOrNull;
    if (wallets == null) return null;

    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  Future<void> _reload() async {
    state = await AsyncValue.guard<List<WalletModel>>(() async {
      final wallets = await _repository.getWallets();
      final transactions = ref.read(financialTransactionStoreProvider);
      return _applyTransactions(wallets, transactions);
    });
  }

  List<WalletModel> _applyTransactions(
    List<WalletModel> wallets,
    List<TransactionModel> transactions,
  ) {
    return [
      for (final wallet in wallets)
        wallet.copyWith(
          balance: wallet.balance + _walletDelta(wallet.id, transactions),
        ),
    ];
  }

  double _walletDelta(String walletId, List<TransactionModel> transactions) {
    var delta = 0.0;

    for (final transaction in transactions) {
      if (transaction.isIncome && transaction.walletId == walletId) {
        delta += transaction.amount;
      } else if (transaction.isExpense && transaction.walletId == walletId) {
        delta -= transaction.amount;
      } else if (transaction.isTransfer) {
        if (transaction.sourceAccount == walletId) {
          delta -= transaction.amount;
        }
        if (transaction.destinationAccount == walletId) {
          delta += transaction.amount;
        }
      }
    }

    return delta;
  }
}

/// Total saldo seluruh wallet yang visible.
final totalWalletBalanceProvider = Provider<double>((ref) {
  final walletsAsync = ref.watch(walletProvider);

  return walletsAsync.maybeWhen(
    data: (wallets) => wallets.fold<double>(
      0,
      (total, wallet) => wallet.isHidden ? total : total + wallet.balance,
    ),
    orElse: () => 0,
  );
});

/// Wallet utama.
final primaryWalletProvider = Provider<WalletModel?>((ref) {
  final walletsAsync = ref.watch(walletProvider);

  return walletsAsync.maybeWhen(
    data: (wallets) {
      final visibleWallets = wallets
          .where((wallet) => !wallet.isHidden)
          .toList(growable: false);
      if (visibleWallets.isEmpty) return null;

      for (final wallet in visibleWallets) {
        if (wallet.isPrimary) return wallet;
      }
      return visibleWallets.first;
    },
    orElse: () => null,
  );
});

/// Wallet yang boleh ditampilkan di UI.
final visibleWalletsProvider = Provider<List<WalletModel>>((ref) {
  final walletsAsync = ref.watch(walletProvider);

  return walletsAsync.maybeWhen(
    data: (wallets) => wallets
        .where((wallet) => !wallet.isHidden)
        .toList(growable: false),
    orElse: () => const [],
  );
});

/// Wallet berdasarkan tipe.
final walletByTypeProvider = Provider.family<List<WalletModel>, WalletType>(
  (ref, type) {
    final wallets = ref.watch(visibleWalletsProvider);
    return wallets.where((wallet) => wallet.type == type).toList(growable: false);
  },
);

/// Total saldo berdasarkan tipe wallet.
final walletBalanceByTypeProvider = Provider.family<double, WalletType>(
  (ref, type) {
    final wallets = ref.watch(walletByTypeProvider(type));
    return wallets.fold<double>(0, (total, wallet) => total + wallet.balance);
  },
);

/// Jumlah wallet aktif.
final walletCountProvider = Provider<int>((ref) {
  return ref.watch(visibleWalletsProvider).length;
});

/// Apakah user sudah memiliki wallet.
final hasWalletProvider = Provider<bool>((ref) {
  return ref.watch(visibleWalletsProvider).isNotEmpty;
});
