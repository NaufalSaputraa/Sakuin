import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables.dart';
import 'daos/wallet_dao.dart';
import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/budget_dao.dart';
import 'daos/chat_dao.dart';
import '../constants/category_defaults.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Wallets, Categories, Transactions, Budgets, ChatMessages, SmartRules],
  daos: [WalletDao, CategoryDao, TransactionDao, BudgetDao, ChatDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _seedInitialData();
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

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'sakuin_db');
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
