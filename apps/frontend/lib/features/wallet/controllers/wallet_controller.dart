import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state_provider.dart';
import '../../finance/state/financial_transaction_store.dart';
import '../../dashboard/models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../repositories/supabase_wallet_repository.dart';
import '../repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return SupabaseWalletRepository();
});

final walletProvider =
    AsyncNotifierProvider<WalletController, List<WalletModel>>(
      WalletController.new,
    );

class WalletController extends AsyncNotifier<List<WalletModel>> {
  WalletRepository get _repository => ref.read(walletRepositoryProvider);

  @override
  Future<List<WalletModel>> build() async {
    ref.watch(currentUserProvider);
    ref.listen<List<TransactionModel>>(
      financialTransactionStoreProvider,
      (previous, next) {
        if (previous == next) return;
        refreshWallets();
      },
    );

    return _repository.getWallets();
  }

  Future<void> refreshWallets() async {
    final previous = state;
    final result = await AsyncValue.guard<List<WalletModel>>(
      _repository.getWallets,
    );

    if (result.hasError && previous.hasValue) {
      state = result.copyWithPrevious(previous);
      return;
    }

    state = result;
  }

  Future<WalletModel?> addWallet(WalletModel wallet) async {
    try {
      final created = await _repository.createWallet(wallet);
      await refreshWallets();
      return created;
    } catch (error, stackTrace) {
      state = AsyncValue<List<WalletModel>>.error(error, stackTrace)
          .copyWithPrevious(state);
      return null;
    }
  }

  Future<bool> updateWallet(WalletModel wallet) async {
    try {
      await _repository.updateWallet(wallet);
      await refreshWallets();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<WalletModel>>.error(error, stackTrace)
          .copyWithPrevious(state);
      return false;
    }
  }

  Future<bool> deleteWallet(String id) async {
    try {
      await _repository.deleteWallet(id);
      await refreshWallets();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<WalletModel>>.error(error, stackTrace)
          .copyWithPrevious(state);
      return false;
    }
  }

  Future<bool> setWalletVisibility(String id, {required bool hidden}) async {
    final wallet = _findWallet(id);
    if (wallet == null) return false;
    return updateWallet(wallet.copyWith(isHidden: hidden));
  }

  Future<bool> setPrimaryWallet(String id) async {
    final wallets = state.valueOrNull;
    if (wallets == null || wallets.isEmpty) return false;

    final target = _findWallet(id);
    if (target == null) return false;

    try {
      for (final wallet in wallets) {
        if (wallet.isPrimary && wallet.id != id) {
          await _repository.updateWallet(wallet.copyWith(isPrimary: false));
        }
      }
      if (!target.isPrimary) {
        await _repository.updateWallet(target.copyWith(isPrimary: true));
      }
      await refreshWallets();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<WalletModel>>.error(error, stackTrace)
          .copyWithPrevious(state);
      return false;
    }
  }

  Future<bool> transferBetweenWallets({
    required String sourceWalletId,
    required String destinationWalletId,
    required double amount,
    String? note,
    String? idempotencyKey,
  }) async {
    if (sourceWalletId == destinationWalletId || amount <= 0 || !amount.isFinite) {
      return false;
    }

    final wallets = state.valueOrNull;
    if (wallets == null) return false;

    final source = _findWalletFrom(wallets, sourceWalletId);
    final destination = _findWalletFrom(wallets, destinationWalletId);
    if (source == null || destination == null) return false;
    if (source.isHidden || destination.isHidden) return false;
    if (source.balance - amount < source.minimumBalance) return false;

    try {
      await ref.read(financialTransactionStoreProvider.notifier).transfer(
        sourceWalletId: sourceWalletId,
        destinationWalletId: destinationWalletId,
        amount: amount,
        note: note,
        idempotencyKey: idempotencyKey,
      );
      await refreshWallets();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue<List<WalletModel>>.error(error, stackTrace)
          .copyWithPrevious(state);
      return false;
    }
  }

  WalletModel? _findWallet(String id) {
    final wallets = state.valueOrNull;
    if (wallets == null) return null;
    return _findWalletFrom(wallets, id);
  }

  WalletModel? _findWalletFrom(List<WalletModel> wallets, String id) {
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }
}

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

final primaryWalletProvider = Provider<WalletModel?>((ref) {
  final walletsAsync = ref.watch(walletProvider);
  return walletsAsync.maybeWhen(
    data: (wallets) {
      final visibleWallets = wallets.where((wallet) => !wallet.isHidden).toList(growable: false);
      if (visibleWallets.isEmpty) return null;
      for (final wallet in visibleWallets) {
        if (wallet.isPrimary) return wallet;
      }
      return visibleWallets.first;
    },
    orElse: () => null,
  );
});

final visibleWalletsProvider = Provider<List<WalletModel>>((ref) {
  final walletsAsync = ref.watch(walletProvider);
  return walletsAsync.maybeWhen(
    data: (wallets) => wallets.where((wallet) => !wallet.isHidden).toList(growable: false),
    orElse: () => const [],
  );
});

final walletByTypeProvider = Provider.family<List<WalletModel>, WalletType>((ref, type) {
  final wallets = ref.watch(visibleWalletsProvider);
  return wallets.where((wallet) => wallet.type == type).toList(growable: false);
});

final walletBalanceByTypeProvider = Provider.family<double, WalletType>((ref, type) {
  final wallets = ref.watch(walletByTypeProvider(type));
  return wallets.fold<double>(0, (total, wallet) => total + wallet.balance);
});

final walletCountProvider = Provider<int>((ref) => ref.watch(visibleWalletsProvider).length);

final hasWalletProvider = Provider<bool>((ref) => ref.watch(visibleWalletsProvider).isNotEmpty);
