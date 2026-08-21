import 'package:json_annotation/json_annotation.dart';
import '../../features/wallets/domain/wallet_model.dart';
import '../../features/categories/domain/category_model.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../../features/budget/domain/budget_model.dart';
import '../../features/smart_rules/domain/smart_rule_model.dart';

part 'export_model.g.dart';

@JsonSerializable()
class ExportBundle {
  final List<WalletModel> wallets;
  final List<CategoryModel> categories;
  final List<TransactionModel> transactions;
  final List<BudgetModel> budgets;
  final List<SmartRuleModel> smartRules;
  final DateTime exportedAt;
  final String version;

  const ExportBundle({
    required this.wallets,
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.smartRules,
    required this.exportedAt,
    this.version = '1.0.0',
  });

  factory ExportBundle.fromJson(Map<String, dynamic> json) =>
      _$ExportBundleFromJson(json);

  Map<String, dynamic> toJson() => _$ExportBundleToJson(this);

  ExportBundle copyWith({
    List<WalletModel>? wallets,
    List<CategoryModel>? categories,
    List<TransactionModel>? transactions,
    List<BudgetModel>? budgets,
    List<SmartRuleModel>? smartRules,
    DateTime? exportedAt,
    String? version,
  }) {
    return ExportBundle(
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      transactions: transactions ?? this.transactions,
      budgets: budgets ?? this.budgets,
      smartRules: smartRules ?? this.smartRules,
      exportedAt: exportedAt ?? this.exportedAt,
      version: version ?? this.version,
    );
  }

  int get totalRecords =>
      wallets.length +
      categories.length +
      transactions.length +
      budgets.length +
      smartRules.length;
}

@JsonSerializable()
class ImportResult {
  final Map<String, int> insertedCounts;
  final List<String> warnings;
  final bool hasErrors;

  const ImportResult({
    required this.insertedCounts,
    required this.warnings,
    this.hasErrors = false,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) =>
      _$ImportResultFromJson(json);

  Map<String, dynamic> toJson() => _$ImportResultToJson(this);

  ImportResult copyWith({
    Map<String, int>? insertedCounts,
    List<String>? warnings,
    bool? hasErrors,
  }) {
    return ImportResult(
      insertedCounts: insertedCounts ?? this.insertedCounts,
      warnings: warnings ?? this.warnings,
      hasErrors: hasErrors ?? this.hasErrors,
    );
  }

  static ImportResult empty() {
    return const ImportResult(
      insertedCounts: {
        'wallets': 0,
        'categories': 0,
        'transactions': 0,
        'budgets': 0,
        'smartRules': 0,
      },
      warnings: [],
      hasErrors: false,
    );
  }

  int get totalInserted => insertedCounts.values.fold(0, (sum, v) => sum + v);
}