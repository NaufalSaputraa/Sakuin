import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/result.dart';
import '../../../services/currency/currency_rate_source.dart';
import '../../../services/export/export_model.dart';
import '../../wallets/domain/wallet_model.dart';
import '../../categories/domain/category_model.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../budget/domain/budget_model.dart';
import '../../smart_rules/domain/smart_rule_model.dart';
import '../domain/backup_repository_interface.dart';

class BackupRepository implements BackupRepositoryInterface {
  final AppDatabase _db;

  BackupRepository(this._db);

  @override
  Future<ExportBundle> exportAll() async {
    // Fetch all data in parallel
    final results = await Future.wait([
      _db.walletDao.getAll(),
      _db.categoryDao.getAll(),
      _db.transactionDao.getByDateRange(
        DateTime(2000),
        DateTime(2100),
      ),
      _db.budgetDao.getActiveBudgets(),
      _db.smartRuleDao.getActive(),
    ]);

    final walletEntries = results[0] as List<WalletEntry>;
    final categoryEntries = results[1] as List<CategoryEntry>;
    final transactionEntries = results[2] as List<TransactionEntry>;
    final budgetEntries = results[3] as List<BudgetEntry>;
    final smartRuleEntries = results[4] as List<SmartRuleEntry>;

    return ExportBundle(
      wallets: walletEntries.map(_walletToDomain).toList(),
      categories: categoryEntries.map(_categoryToDomain).toList(),
      transactions: transactionEntries.map(_transactionToDomain).toList(),
      budgets: budgetEntries.map(_budgetToDomain).toList(),
      smartRules: smartRuleEntries.map(_smartRuleToDomain).toList(),
      exportedAt: DateTime.now(),
    );
  }

  @override
  Future<Result<ImportResult, AppError>> importAll(ExportBundle bundle) async {
    try {
      return await _db.transaction(() async {
        final insertedCounts = <String, int>{
          'wallets': 0,
          'categories': 0,
          'transactions': 0,
          'budgets': 0,
          'smartRules': 0,
        };
        final warnings = <String>[];

        // Track existing IDs to detect collisions
        final existingWalletIds = (await _db.walletDao.getAll()).map((e) => e.id).toSet();
        final existingCategoryIds = (await _db.categoryDao.getAll()).map((e) => e.id).toSet();
        final existingTransactionIds = <int>{};
        final existingBudgetIds = (await _db.budgetDao.getActiveBudgets()).map((e) => e.id).toSet();
        final existingSmartRuleIds = (await _db.smartRuleDao.getActive()).map((e) => e.id).toSet();

        // 1. Import Wallets (must be first for FK references)
        for (final wallet in bundle.wallets) {
          if (existingWalletIds.contains(wallet.id)) {
            warnings.add('Wallet "${wallet.name}" (id: ${wallet.id}) already exists, skipping');
            continue;
          }
          await _db.walletDao.insertWallet(_walletToCompanion(wallet));
          existingWalletIds.add(wallet.id);
          insertedCounts['wallets'] = insertedCounts['wallets']! + 1;
        }

        // 2. Import Categories
        for (final category in bundle.categories) {
          if (existingCategoryIds.contains(category.id)) {
            warnings.add('Category "${category.name}" (id: ${category.id}) already exists, skipping');
            continue;
          }
          await _db.categoryDao.insertCategory(_categoryToCompanion(category));
          existingCategoryIds.add(category.id);
          insertedCounts['categories'] = insertedCounts['categories']! + 1;
        }

        // 3. Import Transactions
        for (final transaction in bundle.transactions) {
          if (existingTransactionIds.contains(transaction.id)) {
            warnings.add('Transaction "${transaction.title}" (id: ${transaction.id}) already exists, skipping');
            continue;
          }
          // Validate FK references
          if (!existingWalletIds.contains(transaction.walletId)) {
            warnings.add('Transaction "${transaction.title}" references missing wallet ${transaction.walletId}, skipping');
            continue;
          }
          if (transaction.categoryId != null && !existingCategoryIds.contains(transaction.categoryId!)) {
            warnings.add('Transaction "${transaction.title}" references missing category ${transaction.categoryId}, skipping');
            continue;
          }
          if (transaction.transferToWalletId != null && !existingWalletIds.contains(transaction.transferToWalletId!)) {
            warnings.add('Transaction "${transaction.title}" references missing transfer wallet ${transaction.transferToWalletId}, skipping');
            continue;
          }

          // Restore strategy: wallet balances were already inserted as-is
          // from the bundle above (reconciled by wallet id), so insert
          // transactions WITHOUT re-applying balance deltas to avoid
          // double-counting on re-import / different device.
          await _db.transactionDao.insertTransaction(
            await _transactionToCompanion(transaction),
            skipBalanceUpdate: true,
          );
          existingTransactionIds.add(transaction.id);
          insertedCounts['transactions'] = insertedCounts['transactions']! + 1;
        }

        // 4. Import Budgets
        for (final budget in bundle.budgets) {
          if (existingBudgetIds.contains(budget.id)) {
            warnings.add('Budget "${budget.name}" (id: ${budget.id}) already exists, skipping');
            continue;
          }
          if (budget.categoryId != null && !existingCategoryIds.contains(budget.categoryId!)) {
            warnings.add('Budget "${budget.name}" references missing category ${budget.categoryId}, skipping');
            continue;
          }
          if (budget.walletId != null && !existingWalletIds.contains(budget.walletId!)) {
            warnings.add('Budget "${budget.name}" references missing wallet ${budget.walletId}, skipping');
            continue;
          }

          await _db.budgetDao.insertBudget(_budgetToCompanion(budget));
          existingBudgetIds.add(budget.id);
          insertedCounts['budgets'] = insertedCounts['budgets']! + 1;
        }

        // 5. Import Smart Rules
        for (final rule in bundle.smartRules) {
          if (existingSmartRuleIds.contains(rule.id)) {
            warnings.add('Smart Rule "${rule.name}" (id: ${rule.id}) already exists, skipping');
            continue;
          }
          await _db.smartRuleDao.insertRule(_smartRuleToCompanion(rule));
          existingSmartRuleIds.add(rule.id);
          insertedCounts['smartRules'] = insertedCounts['smartRules']! + 1;
        }

        return Success(ImportResult(
          insertedCounts: insertedCounts,
          warnings: warnings,
          hasErrors: false,
        ));
      });
    } catch (e) {
      return Failure(AppError.database('Import failed: $e'));
    }
  }

  // Conversion methods: Domain -> Drift Companion
  WalletsCompanion _walletToCompanion(WalletModel wallet) {
    return WalletsCompanion.insert(
      id: Value(wallet.id),
      name: wallet.name,
      walletType: wallet.walletType,
      parentId: Value(wallet.parentId),
      provider: Value(wallet.provider),
      balance: Value(wallet.balance),
      currency: Value(wallet.currency),
      icon: Value(wallet.icon),
      color: Value(wallet.color),
      isActive: Value(wallet.isActive),
      createdAt: Value(wallet.createdAt),
      updatedAt: Value(wallet.updatedAt),
    );
  }

  CategoriesCompanion _categoryToCompanion(CategoryModel category) {
    return CategoriesCompanion.insert(
      id: Value(category.id),
      key: category.key,
      name: category.name,
      nameId: Value(category.nameId),
      icon: category.icon,
      color: category.color,
      parentId: Value(category.parentId),
      isDefault: Value(category.isDefault),
      isIncome: Value(category.isIncome),
      sortOrder: Value(category.sortOrder),
    );
  }

  Future<TransactionsCompanion> _transactionToCompanion(
      TransactionModel transaction) async {
    // Preserve the exported amountBase; recompute only when it is missing
    // (0) so imported rows don't collapse to IDR 0 in monthly totals.
    var amountBase = transaction.amountBase;
    if (amountBase <= 0) {
      amountBase = await CurrencyRateSource.computeAmountBase(
        transaction.amount,
        transaction.currency,
        _db.currencyRatesDao,
      );
    }
    return TransactionsCompanion.insert(
      id: Value(transaction.id),
      walletId: transaction.walletId,
      categoryId: Value(transaction.categoryId),
      amount: transaction.amount,
      transactionType: transaction.transactionType.toDbString(),
      title: transaction.title,
      description: Value(transaction.description),
      merchant: Value(transaction.merchant),
      sourceInput: Value(transaction.sourceInput),
      rawInput: Value(transaction.rawInput),
      transferToWalletId: Value(transaction.transferToWalletId),
      currency: Value(transaction.currency),
      amountBase: Value(amountBase),
      transactionDate: Value(transaction.transactionDate),
      createdAt: Value(transaction.createdAt),
      updatedAt: Value(transaction.updatedAt),
    );
  }

  BudgetsCompanion _budgetToCompanion(BudgetModel budget) {
    return BudgetsCompanion.insert(
      id: Value(budget.id),
      name: budget.name,
      budgetType: budget.budgetType.toDbString(),
      amount: budget.amount,
      period: Value(budget.period),
      categoryId: Value(budget.categoryId),
      walletId: Value(budget.walletId),
      startDate: Value(budget.startDate),
      endDate: Value(budget.endDate),
      isActive: Value(budget.isActive),
      createdAt: Value(budget.createdAt),
    );
  }

  SmartRulesCompanion _smartRuleToCompanion(SmartRuleModel rule) {
    return SmartRulesCompanion.insert(
      id: Value(rule.id),
      name: rule.name,
      isActive: Value(rule.isActive),
      conditions: jsonEncode(rule.conditions.map((c) => c.toJson()).toList()),
      actionType: rule.action.type.toDbString(),
      actionValue: rule.action.value,
      priority: Value(rule.priority),
      createdAt: Value(rule.createdAt),
    );
  }

  // Conversion methods: Drift Entry -> Domain Model
  WalletModel _walletToDomain(WalletEntry entry) {
    return WalletModel(
      id: entry.id,
      name: entry.name,
      walletType: entry.walletType,
      parentId: entry.parentId,
      provider: entry.provider,
      balance: entry.balance,
      currency: entry.currency,
      icon: entry.icon,
      color: entry.color,
      isActive: entry.isActive,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  CategoryModel _categoryToDomain(CategoryEntry entry) {
    return CategoryModel.fromEntry(entry);
  }

  TransactionModel _transactionToDomain(TransactionEntry entry) {
    return TransactionModel(
      id: entry.id,
      walletId: entry.walletId,
      categoryId: entry.categoryId,
      amount: entry.amount,
      transactionType: TransactionType.fromString(entry.transactionType),
      title: entry.title,
      description: entry.description,
      merchant: entry.merchant,
      sourceInput: entry.sourceInput,
      rawInput: entry.rawInput,
      transferToWalletId: entry.transferToWalletId,
      transactionDate: entry.transactionDate,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  BudgetModel _budgetToDomain(BudgetEntry entry) {
    return BudgetModel(
      id: entry.id,
      name: entry.name,
      budgetType: BudgetType.fromString(entry.budgetType),
      amount: entry.amount,
      period: entry.period,
      categoryId: entry.categoryId,
      walletId: entry.walletId,
      startDate: entry.startDate,
      endDate: entry.endDate,
      isActive: entry.isActive,
      createdAt: entry.createdAt,
    );
  }

  SmartRuleModel _smartRuleToDomain(SmartRuleEntry entry) {
    final conditionsJson = jsonDecode(entry.conditions) as List<dynamic>;
    final actionJson = jsonDecode(entry.actionValue) as Map<String, dynamic>;

    return SmartRuleModel(
      id: entry.id,
      name: entry.name,
      isActive: entry.isActive,
      conditions: conditionsJson
          .map((e) => RuleCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      action: RuleAction.fromJson(actionJson),
      priority: entry.priority,
      createdAt: entry.createdAt,
    );
  }
}