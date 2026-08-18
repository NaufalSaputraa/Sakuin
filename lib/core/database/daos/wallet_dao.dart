import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [Wallets, Transactions])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  Stream<List<WalletEntry>> watchAll() {
    return (select(wallets)..where((t) => t.isActive.equals(true))).watch();
  }

  Future<List<WalletEntry>> getAll() {
    return (select(wallets)..where((t) => t.isActive.equals(true))).get();
  }

  Future<WalletEntry?> getById(int id) {
    return (select(wallets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<WalletEntry>> watchSubWallets(int parentId) {
    return (select(wallets)
          ..where((t) => t.parentId.equals(parentId) & t.isActive.equals(true)))
        .watch();
  }

  Future<int> insertWallet(WalletsCompanion companion) {
    return into(wallets).insert(companion);
  }

  Future<bool> updateWallet(WalletEntry entry) {
    return update(wallets).replace(entry);
  }

  Future<int> updateBalance(int walletId, double delta) async {
    final wallet = await getById(walletId);
    if (wallet == null) return 0;
    final newBalance = wallet.balance + delta;
    return (update(wallets)..where((t) => t.id.equals(walletId))).write(
      WalletsCompanion(
        balance: Value(newBalance),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<double> watchTotalBalance() {
    return select(wallets).watch().map((list) {
      // Sum root physical wallet + all digital wallets (root + sub-wallets)
      // Note: If sub-wallets exist, sum sub-wallets + physical wallet
      final subWallets = list.where((w) => w.parentId != null && w.isActive);
      final physical = list.where((w) => w.walletType == 'physical' && w.isActive);
      
      if (subWallets.isNotEmpty) {
        final subTotal = subWallets.fold(0.0, (sum, w) => sum + w.balance);
        final physTotal = physical.fold(0.0, (sum, w) => sum + w.balance);
        return subTotal + physTotal;
      } else {
        return list.where((w) => w.isActive).fold(0.0, (sum, w) => sum + w.balance);
      }
    });
  }
}
