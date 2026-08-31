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

  });
}
