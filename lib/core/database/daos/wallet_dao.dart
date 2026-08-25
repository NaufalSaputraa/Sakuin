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

  Future<int> deleteWallet(int id) =>
      (delete(wallets)..where((t) => t.id.equals(id))).go();

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
      // Sum all active wallets regardless of parentId/walletType.
      // Previous conditional excluded digital root when sub-wallets exist,
      // causing balance mismatch (e.g. digital root balance dropped).
      // Now consistently sum all active wallets (physical + digital root + sub-wallets)
      // so total is always accurate even after seeding multiple sub-wallets.
      return list.where((w) => w.isActive).fold(0.0, (sum, w) => sum + w.balance);
    });
  }
}
