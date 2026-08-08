import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet_model.dart';
import '../repositories/wallet_repository.dart';

/// Repository dependency.
///
/// Saat backend Supabase siap, repository bisa diganti tanpa
/// perlu mengubah widget Wallet.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return MockWalletRepository();
});

/// Main wallet state.
final walletProvider =
    AsyncNotifierProvider<WalletController, List<WalletModel>>(
      WalletController.new,
    );

class WalletController extends AsyncNotifier<List<WalletModel>> {
  WalletRepository get _repository {
    return ref.read(walletRepositoryProvider);
  }

  @override
  Future<List<WalletModel>> build() async {
    return _loadWallets();
  }

  Future<List<WalletModel>> _loadWallets() {
    return _repository.getWallets();
  }

  /// Refresh wallet tanpa sengaja membuang data lama dari UI.
  Future<void> refreshWallets() async {
    final previous = state;

    final result = await AsyncValue.guard<List<WalletModel>>(_loadWallets);

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

    if (wallet == null) {
      return false;
    }

    return updateWallet(wallet.copyWith(isHidden: hidden));
  }

  /// Menjadikan wallet tertentu sebagai wallet utama.
  ///
  /// Hanya satu wallet yang boleh primary.
  Future<bool> setPrimaryWallet(String id) async {
    final wallets = state.valueOrNull;

    if (wallets == null || wallets.isEmpty) {
      return false;
    }

    final target = _findWallet(id);

    if (target == null) {
      return false;
    }

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

    if (wallets == null) {
      return null;
    }

    for (final wallet in wallets) {
      if (wallet.id == id) {
        return wallet;
      }
    }

    return null;
  }

  Future<void> _reload() async {
    state = await AsyncValue.guard<List<WalletModel>>(_loadWallets);
  }
}

/// Total saldo seluruh wallet yang visible.
final totalWalletBalanceProvider = Provider<double>((ref) {
  final walletsAsync = ref.watch(walletProvider);

  return walletsAsync.maybeWhen(
    data: (wallets) {
      return wallets.fold<double>(0, (total, wallet) {
        if (wallet.isHidden) {
          return total;
        }

        return total + wallet.balance;
      });
    },
    orElse: () => 0,
  );
});

/// Wallet utama.
///
/// Kalau tidak ada yang ditandai primary,
/// wallet visible pertama digunakan sebagai fallback.
final primaryWalletProvider = Provider<WalletModel?>((ref) {
  final walletsAsync = ref.watch(walletProvider);

  return walletsAsync.maybeWhen(
    data: (wallets) {
      final visibleWallets = wallets
          .where((wallet) => !wallet.isHidden)
          .toList(growable: false);

      if (visibleWallets.isEmpty) {
        return null;
      }

      for (final wallet in visibleWallets) {
        if (wallet.isPrimary) {
          return wallet;
        }
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
    data: (wallets) {
      return wallets
          .where((wallet) => !wallet.isHidden)
          .toList(growable: false);
    },
    orElse: () => const [],
  );
});

/// Wallet berdasarkan tipe.
final walletByTypeProvider = Provider.family<List<WalletModel>, WalletType>((
  ref,
  type,
) {
  final wallets = ref.watch(visibleWalletsProvider);

  return wallets.where((wallet) => wallet.type == type).toList(growable: false);
});

/// Total saldo berdasarkan tipe wallet.
final walletBalanceByTypeProvider = Provider.family<double, WalletType>((
  ref,
  type,
) {
  final wallets = ref.watch(walletByTypeProvider(type));

  return wallets.fold<double>(0, (total, wallet) => total + wallet.balance);
});

/// Jumlah wallet aktif.
final walletCountProvider = Provider<int>((ref) {
  return ref.watch(visibleWalletsProvider).length;
});

/// Apakah user sudah memiliki wallet.
final hasWalletProvider = Provider<bool>((ref) {
  return ref.watch(visibleWalletsProvider).isNotEmpty;
});
