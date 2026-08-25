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

  /// Inserts a transaction row.
  ///
  /// By default this also applies wallet balance deltas (expense/income/
  /// transfer). Pass [skipBalanceUpdate] = true ONLY for restore/import flows
  /// where wallet balances were already restored as-is from the backup bundle;
  /// re-running the deltas there would double-count them.
  Future<int> insertTransaction(
    TransactionsCompanion companion, {
    bool skipBalanceUpdate = false,
  }) async {
    return db.transaction(() async {
      final txId = await into(transactions).insert(companion);

      if (!skipBalanceUpdate) {
        final walletId = companion.walletId.value;
        // Balance deltas use the base-currency (IDR) amount so multi-currency
        // transactions adjust balances correctly (wallets are IDR-based).
        final amount = companion.amountBase.present && companion.amountBase.value != 0
            ? companion.amountBase.value
            : companion.amount.value;
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
      }

      return txId;
    });
  }

  Future<int> deleteTransaction(int id) async {
    return db.transaction(() async {
      final tx = await (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (tx == null) return 0;

      // Revert wallet balances (amountBase = IDR-equivalent amount)
      if (tx.transactionType == 'expense') {
        await db.walletDao.updateBalance(tx.walletId, tx.amountBase);
      } else if (tx.transactionType == 'income') {
        await db.walletDao.updateBalance(tx.walletId, -tx.amountBase);
      } else if (tx.transactionType == 'transfer' && tx.transferToWalletId != null) {
        await db.walletDao.updateBalance(tx.walletId, tx.amountBase);
        await db.walletDao.updateBalance(tx.transferToWalletId!, -tx.amountBase);
      }

      return (delete(transactions)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Updates a transaction row, reverting the old wallet balance deltas and
  /// applying the new ones so wallet balances stay consistent after an edit.
  Future<int> updateTransaction(int id, TransactionsCompanion companion) {
    return db.transaction(() async {
      final old = await (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (old == null) return 0;

      // Revert old balance effect (amountBase = IDR-equivalent amount)
      if (old.transactionType == 'expense') {
        await db.walletDao.updateBalance(old.walletId, old.amountBase);
      } else if (old.transactionType == 'income') {
        await db.walletDao.updateBalance(old.walletId, -old.amountBase);
      } else if (old.transactionType == 'transfer' && old.transferToWalletId != null) {
        await db.walletDao.updateBalance(old.walletId, old.amountBase);
        await db.walletDao.updateBalance(old.transferToWalletId!, -old.amountBase);
      }

      // Apply new balance effect
      final walletId = companion.walletId.present ? companion.walletId.value : old.walletId;
      final amountBase = companion.amountBase.present ? companion.amountBase.value : old.amountBase;
      final type = companion.transactionType.present ? companion.transactionType.value : old.transactionType;
      final transferToWalletId = companion.transferToWalletId.present
          ? companion.transferToWalletId.value
          : old.transferToWalletId;

      if (type == 'expense') {
        await db.walletDao.updateBalance(walletId, -amountBase);
      } else if (type == 'income') {
        await db.walletDao.updateBalance(walletId, amountBase);
      } else if (type == 'transfer' && transferToWalletId != null) {
        await db.walletDao.updateBalance(walletId, -amountBase);
        await db.walletDao.updateBalance(transferToWalletId, amountBase);
      }

      return (update(transactions)..where((t) => t.id.equals(id))).write(companion);
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
