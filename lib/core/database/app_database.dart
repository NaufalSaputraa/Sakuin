import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables.dart';
import 'daos/wallet_dao.dart';
import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/budget_dao.dart';
import 'daos/chat_dao.dart';
import 'daos/smart_rule_dao.dart';
import 'daos/subscription_dao.dart';
import 'daos/currency_rates_dao.dart';
import '../constants/category_defaults.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Wallets, Categories, Transactions, Budgets, ChatMessages, SmartRules, Subscriptions, CurrencyRates],
  daos: [WalletDao, CategoryDao, TransactionDao, BudgetDao, ChatDao, SmartRuleDao, SubscriptionDao, CurrencyRatesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _seedInitialData();
        await _seedCurrencyRates();
      },
      onUpgrade: (m, from, to) async {
        // NOTE: Backup WAJIB before destructive migration (AGENTS.md).
        // v1 -> v2: create subscriptions table.
        if (from < 2) {
          await m.createTable(subscriptions);
        }
        // v2 -> v3: add currency support.
        // - create currency_rates table
        // - add currency + amountBase columns to transactions (safe defaults)
        if (from < 3) {
          await m.createTable(currencyRates);
          await m.addColumn(transactions, transactions.currency);
          await m.addColumn(transactions, transactions.amountBase);
          await _seedCurrencyRates();
        }
      },
    );
  }

  Future<void> _seedInitialData() async {
    // 1. Seed Dual Root Wallets
    await into(wallets).insert(
      WalletsCompanion.insert(
        name: 'Dompet Fisik',
        walletType: 'physical',
        currency: const Value('IDR'),
        icon: const Value('💵'),
        color: const Value('#2ECC71'),
      ),
    );

    final digitalRootId = await into(wallets).insert(
      WalletsCompanion.insert(
        name: 'Dompet Digital',
        walletType: 'digital',
        currency: const Value('IDR'),
        icon: const Value('📱'),
        color: const Value('#3B82C4'),
      ),
    );

    // 2. Seed Default Sub-Wallets under Digital Root
    await into(wallets).insert(
      WalletsCompanion.insert(
        name: 'GoPay',
        walletType: 'digital',
        parentId: Value(digitalRootId),
        provider: const Value('gopay'),
        currency: const Value('IDR'),
        icon: const Value('📱'),
        color: const Value('#00AED6'),
      ),
    );

    await into(wallets).insert(
      WalletsCompanion.insert(
        name: 'OVO',
        walletType: 'digital',
        parentId: Value(digitalRootId),
        provider: const Value('ovo'),
        currency: const Value('IDR'),
        icon: const Value('📱'),
        color: const Value('#4C2A86'),
      ),
    );

    await into(wallets).insert(
      WalletsCompanion.insert(
        name: 'Dana',
        walletType: 'digital',
        parentId: Value(digitalRootId),
        provider: const Value('dana'),
        currency: const Value('IDR'),
        icon: const Value('📱'),
        color: const Value('#118EEA'),
      ),
    );

    await into(wallets).insert(
      WalletsCompanion.insert(
        name: 'ShopeePay',
        walletType: 'digital',
        parentId: Value(digitalRootId),
        provider: const Value('shopeepay'),
        currency: const Value('IDR'),
        icon: const Value('📱'),
        color: const Value('#EE4D2D'),
      ),
    );

    // 3. Seed Default Categories
    for (final item in CategoryDefaults.defaults) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          key: item.key,
          name: item.name,
          nameId: Value(item.nameId),
          icon: item.icon,
          color: item.colorHex,
          isDefault: const Value(true),
          isIncome: Value(item.isIncome),
          sortOrder: Value(item.sortOrder),
        ),
      );
    }

    // 4. Seed Initial Welcome Chat Message
    await into(chatMessages).insert(
      ChatMessagesCompanion.insert(
        content: 'Halo! Saya asisten keuangan Google Gemma AI di Sakuin. Saya bisa menganalisis anggaranmu, memberikan saran hemat, dan kamu juga bisa langsung menyuruh saya mencatat pengeluaran (baik satu per satu maupun berupa daftar/list pengeluaran sekaligus)!',
        isUser: false,
      ),
    );
  }

  /// Seed default offline currency rates (static, relative to IDR).
  /// Called on fresh install (onCreate) and on upgrade to v3 so the
  /// rates table is never empty.
  Future<void> _seedCurrencyRates() async {
    const seed = [
      _SeedRate(code: 'IDR', name: 'Indonesian Rupiah', rateToIdr: 1.0, isBase: true),
      _SeedRate(code: 'USD', name: 'US Dollar', rateToIdr: 15500.0, isBase: false),
      _SeedRate(code: 'SGD', name: 'Singapore Dollar', rateToIdr: 11500.0, isBase: false),
      _SeedRate(code: 'EUR', name: 'Euro', rateToIdr: 16800.0, isBase: false),
      _SeedRate(code: 'JPY', name: 'Japanese Yen', rateToIdr: 105.0, isBase: false),
      _SeedRate(code: 'MYR', name: 'Malaysian Ringgit', rateToIdr: 3500.0, isBase: false),
    ];

    for (final s in seed) {
      await into(currencyRates).insertOnConflictUpdate(
        CurrencyRatesCompanion.insert(
          code: s.code,
          name: s.name,
          rateToIdr: s.rateToIdr,
          isBase: Value(s.isBase),
        ),
      );
    }
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'sakuin_db');
  }
}

class _SeedRate {
  final String code;
  final String name;
  final double rateToIdr;
  final bool isBase;
  const _SeedRate({
    required this.code,
    required this.name,
    required this.rateToIdr,
    required this.isBase,
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
