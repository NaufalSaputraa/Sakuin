import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_model.dart';
import '../domain/wallet_repository_interface.dart';

final walletRepositoryProvider = Provider<WalletRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return WalletRepository(db);
});

final allWalletsProvider = StreamProvider.autoDispose<List<WalletModel>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchAll();
});

final physicalWalletProvider = StreamProvider.autoDispose<WalletModel?>((ref) {
  final walletsAsync = ref.watch(allWalletsProvider);
  return walletsAsync.when(
    data: (wallets) => Stream.value(wallets.where((w) => w.isPhysical).firstOrNull),
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

final digitalRootWalletProvider = StreamProvider.autoDispose<WalletModel?>((ref) {
  final walletsAsync = ref.watch(allWalletsProvider);
  return walletsAsync.when(
    data: (wallets) => Stream.value(wallets.where((w) => w.isDigital && w.parentId == null).firstOrNull),
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

final digitalSubWalletsProvider = StreamProvider.autoDispose<List<WalletModel>>((ref) {
  final walletsAsync = ref.watch(allWalletsProvider);
  return walletsAsync.when(
    data: (wallets) => Stream.value(wallets.where((w) => w.parentId != null).toList()),
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

final totalBalanceProvider = StreamProvider.autoDispose<double>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchTotalBalance();
});

final subWalletsProvider = StreamProvider.autoDispose.family<List<WalletModel>, int>((ref, parentId) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchSubWallets(parentId);
});

class SelectedWalletNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? walletId) {
    state = walletId;
  }
}

final selectedWalletProvider = NotifierProvider<SelectedWalletNotifier, int?>(() {
  return SelectedWalletNotifier();
});
