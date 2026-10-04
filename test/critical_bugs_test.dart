import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/core/database/app_database.dart';
import 'package:sakuin_app/features/settings/data/backup_repository.dart';
import 'package:sakuin_app/features/smart_rules/data/smart_rule_repository.dart';
import 'package:sakuin_app/features/smart_rules/domain/smart_rule_model.dart';
import 'package:sakuin_app/features/transactions/domain/transaction_model.dart';
import 'package:sakuin_app/features/wallets/domain/wallet_model.dart';
import 'package:sakuin_app/services/export/export_model.dart';
import 'package:sakuin_app/services/export/import_service.dart';
import 'package:sakuin_app/services/ml/smart_rule_learning_service.dart';
import 'package:sakuin_app/services/subscription_detector_service.dart';

/// Regression tests for critical bugs that `flutter analyze` cannot catch
/// (C1/C2/M1/M3): multi-currency integrity through export/import, DAO
/// balance math using amountBase, merchant fallback to title, and import
/// skipBalanceUpdate semantics.
///
/// All tests run against a Drift in-memory database seeded like production
/// (root wallets + sub-wallets + default categories).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Builds a [TransactionModel] with sensible defaults for tests.
  TransactionModel makeTx({
    required int id,
    required int walletId,
    double amount = 10,
    String type = 'expense',
    String title = 'Kopi',
    String? merchant,
    String currency = 'IDR',
    double amountBase = 0,
    DateTime? date,
  }) {
    final d = date ?? DateTime.now();
    return TransactionModel(
      id: id,
      walletId: walletId,
      amount: amount,
      transactionType: TransactionType.fromString(type),
      title: title,
      merchant: merchant,
      currency: currency,
      amountBase: amountBase,
      transactionDate: d,
      createdAt: d,
      updatedAt: d,
    );
  }

  group('Critical bugs C1/C2/M1/M3 regression', () {
    // C1: Importing a backup must preserve the original transaction
    // currency and its pre-computed amountBase instead of collapsing
    // foreign-currency rows to IDR with amountBase 0.
    test('importAll preserves currency+amountBase', () async {
      final repo = BackupRepository(db);
      final now = DateTime.now();

      final bundle = ExportBundle(
        wallets: [
          WalletModel(
            id: 100,
            name: 'Foreign Cash',
            walletType: 'physical',
            balance: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        categories: const [],
        transactions: [
          makeTx(
            id: 500,
            walletId: 100,
            amount: 10,
            currency: 'USD',
            amountBase: 155000,
            title: 'Coffee NYC',
            merchant: 'Blue Bottle',
          ),
        ],
        budgets: const [],
        smartRules: const [],
        exportedAt: now,
      );

      final result = await repo.importAll(bundle);
      expect(result.isSuccess, isTrue,
          reason: 'importAll failed: ${result.errorOrNull?.message}');

      final row = await (db.select(db.transactions)
            ..where((t) => t.id.equals(500)))
          .getSingle();

      expect(row.currency, 'USD', reason: 'currency must survive import');
      expect(row.amountBase, closeTo(155000, 0.01),
          reason: 'amountBase must be preserved, not reset to IDR 0');
      expect(row.amount, closeTo(10, 0.01));
    });

    // C2: Wallet balance deltas (insert + delete revert) must operate on
    // amountBase (IDR-equivalent), never the raw foreign amount.
    test('transactionDao balance uses amountBase', () async {
      final walletId = await db.walletDao.insertWallet(
        WalletsCompanion.insert(name: 'Cash USD', walletType: 'physical'),
      );

      final txId = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          walletId: walletId,
          amount: 10,
          transactionType: 'income',
          title: 'Freelance USD',
          currency: const Value('USD'),
          amountBase: const Value(155000),
          transactionDate: Value(DateTime.now()),
        ),
      );
      expect(txId, greaterThan(0));

      // Income of USD 10 must credit 155000 IDR-equivalent, not 10.
      var wallet = await db.walletDao.getById(walletId);
      expect(wallet!.balance, closeTo(155000, 0.01),
          reason: 'balance must grow by amountBase (155000), not amount (10)');

      // Deleting the transaction must revert the same amountBase delta.
      await db.transactionDao.deleteTransaction(txId);
      wallet = await db.walletDao.getById(walletId);
      expect(wallet!.balance, closeTo(0, 0.01),
          reason: 'delete must revert by amountBase (155000)');
    });

    // M1: Legacy rows created before merchant propagation have merchant ==
    // null. Detection and rule learning must fall back to title instead of
    // returning empty results.
    test('detector fallback merchant ?? title', () async {
      final now = DateTime.now();
      final t1 = now.subtract(const Duration(days: 60));
      final t2 = now.subtract(const Duration(days: 30));

      // --- SubscriptionDetectorService ---
      final txs = [
        makeTx(id: 1, walletId: 1, amount: 20000, title: 'Warung Kopi', date: t1),
        makeTx(id: 2, walletId: 1, amount: 20000, title: 'Warung Kopi', date: t2),
        makeTx(id: 3, walletId: 1, amount: 20000, title: 'Warung Kopi', date: now),
      ];
      for (final tx in txs) {
        expect(tx.merchant, isNull, reason: 'precondition: merchant is null');
      }

      final detections = SubscriptionDetectorService().detect(txs);
      expect(detections, isNotEmpty,
          reason: 'null merchant must fall back to title, not yield empty');
      expect(detections.first.merchant, 'Warung Kopi');
      expect(detections.first.normalizedKey, 'warungkopi');
      expect(detections.first.occurrenceCount, 3);

      // --- SmartRuleLearningService (DB-backed) ---
      final catId = (await db.categoryDao.getAll()).first.id;
      for (final date in [t1, t2, now]) {
        await db.transactionDao.insertTransaction(
          TransactionsCompanion.insert(
            walletId: 1, // seeded "Dompet Fisik"
            categoryId: Value(catId),
            amount: 20000,
            transactionType: 'expense',
            title: 'Warung Kopi',
            // merchant omitted -> stored NULL (legacy row shape)
            transactionDate: Value(date),
          ),
        );
      }

      final learning = SmartRuleLearningService(db, SmartRuleRepository(db));
      final rules = await learning.generateFromHistory();
      expect(rules, isNotEmpty,
          reason: 'rule learning must use title fallback for null merchant');
      expect(rules.first.conditions.first.field, RuleField.merchant);
      expect(rules.first.conditions.first.value, 'warung kopi');
    });

    // M3: importAll restores wallet balances as-is from the bundle and must
    // NOT re-apply transaction deltas on top (double-counting).
    test('import skipBalanceUpdate', () async {
      final repo = BackupRepository(db);
      final now = DateTime.now();

      final bundle = ExportBundle(
        wallets: [
          WalletModel(
            id: 200,
            name: 'GoPay Backup',
            walletType: 'digital',
            provider: 'gopay',
            balance: 100000,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        categories: const [],
        transactions: [
          makeTx(
            id: 600,
            walletId: 200,
            amount: 50000,
            amountBase: 50000,
            title: 'Kopi Kenangan',
          ),
        ],
        budgets: const [],
        smartRules: const [],
        exportedAt: now,
      );

      final result = await repo.importAll(bundle);
      expect(result.isSuccess, isTrue,
          reason: 'importAll failed: ${result.errorOrNull?.message}');
      expect(result.valueOrNull!.insertedCounts['transactions'], 1);

      final wallet = await db.walletDao.getById(200);
      expect(wallet, isNotNull);
      expect(wallet!.balance, closeTo(100000, 0.01),
          reason:
              'balance was restored as-is from the bundle; applying the '
              '50000 expense delta again would corrupt it (150000/50000)');
    });

    test('walletDao.deleteWallet performs soft-delete without foreign key crash', () async {
      final now = DateTime.now();
      final rootId = await db.walletDao.insertWallet(
        WalletsCompanion.insert(
          name: 'Digital Root',
          walletType: 'digital',
          balance: const Value(500000),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final walletId = await db.walletDao.insertWallet(
        WalletsCompanion.insert(
          name: 'Dana Test',
          walletType: 'digital',
          provider: const Value('dana'),
          parentId: Value(rootId),
          balance: const Value(200000),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Create transaction linked to wallet
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          walletId: walletId,
          amount: 50000,
          transactionType: 'expense',
          title: 'Makan Siang',
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Soft delete wallet
      final rowsAffected = await db.walletDao.deleteWallet(walletId);
      expect(rowsAffected, 1);

      // Verify it no longer appears in active wallets
      final activeWallets = await db.walletDao.getAll();
      expect(activeWallets.any((w) => w.id == walletId), isFalse);

      // But still exists in DB as inactive
      final rawWallet = await (db.select(db.wallets)..where((w) => w.id.equals(walletId))).getSingleOrNull();
      expect(rawWallet, isNotNull);
      expect(rawWallet!.isActive, isFalse);
    });

    test('ImportService.parseCsv parses CRLF Windows line endings and 14-column header', () async {
      const importService = ImportService();
      const csvData =
          "id,walletId,categoryId,amount,type,title,date,description,merchant,sourceInput,rawInput,transferToWalletId,createdAt,updatedAt\r\n"
          "1,1,,25000.0,expense,Kopi Kenangan,2026-10-04T10:00:00.000Z,Ngopi pagi,Kopi Kenangan,manual,,0,2026-10-04T10:00:00.000Z,2026-10-04T10:00:00.000Z\r\n";

      final parseResult = await importService.parseCsv(csvData);
      expect(parseResult.isSuccess, isTrue,
          reason: 'CSV with CRLF failed: ${parseResult.errorOrNull?.message}');
      final bundle = parseResult.valueOrNull!;
      expect(bundle.transactions.length, 1);
      expect(bundle.transactions.first.title, 'Kopi Kenangan');
      expect(bundle.transactions.first.amount, 25000.0);
    });
  });
}
