import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Wallets, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<TransactionEntry>> watchRecent({int limit = 20}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }

  Stream<List<TransactionEntry>> watchByWallet(int walletId) {
    return (select(transactions)
          ..where((t) => t.walletId.equals(walletId) | t.transferToWalletId.equals(walletId))
          ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<TransactionEntry>> watchByDateRange(DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) => t.transactionDate.isBiggerOrEqualValue(start) & t.transactionDate.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<TransactionEntry>> getByDateRange(DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) => t.transactionDate.isBiggerOrEqualValue(start) & t.transactionDate.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
        .get();
  }

  Future<int> insertTransaction(TransactionsCompanion companion) async {
    return db.transaction(() async {
      final txId = await into(transactions).insert(companion);

      final walletId = companion.walletId.value;
      final amount = companion.amount.value;
      final type = companion.transactionType.value;

      if (type == 'expense') {
        await db.walletDao.updateBalance(walletId, -amount);
      } else if (type == 'income') {
        await db.walletDao.updateBalance(walletId, amount);
      } else if (type == 'transfer' && companion.transferToWalletId.present) {
        final toWalletId = companion.transferToWalletId.value;
        if (toWalletId != null) {
          await db.walletDao.updateBalance(walletId, -amount);
          await db.walletDao.updateBalance(toWalletId, amount);
        }
      }

      return txId;
    });
  }

  Future<int> deleteTransaction(int id) async {
    return db.transaction(() async {
      final tx = await (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (tx == null) return 0;

      // Revert wallet balances
      if (tx.transactionType == 'expense') {
        await db.walletDao.updateBalance(tx.walletId, tx.amount);
      } else if (tx.transactionType == 'income') {
        await db.walletDao.updateBalance(tx.walletId, -tx.amount);
      } else if (tx.transactionType == 'transfer' && tx.transferToWalletId != null) {
        await db.walletDao.updateBalance(tx.walletId, tx.amount);
        await db.walletDao.updateBalance(tx.transferToWalletId!, -tx.amount);
      }

      return (delete(transactions)..where((t) => t.id.equals(id))).go();
    });
  }

  Stream<double> watchTotalIncomeForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return (select(transactions)
          ..where((t) =>
              t.transactionType.equals('income') &
              t.transactionDate.isBiggerOrEqualValue(start) &
              t.transactionDate.isSmallerOrEqualValue(end)))
        .watch()
        .map((list) => list.fold(0.0, (sum, tx) => sum + tx.amountBase));
  }

  Stream<double> watchTotalExpenseForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return (select(transactions)
          ..where((t) =>
              t.transactionType.equals('expense') &
              t.transactionDate.isBiggerOrEqualValue(start) &
              t.transactionDate.isSmallerOrEqualValue(end)))
        .watch()
        .map((list) => list.fold(0.0, (sum, tx) => sum + tx.amountBase));
  }
}
