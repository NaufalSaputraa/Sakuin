// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportBundle _$ExportBundleFromJson(Map<String, dynamic> json) => ExportBundle(
  wallets: (json['wallets'] as List<dynamic>)
      .map((e) => WalletModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  categories: (json['categories'] as List<dynamic>)
      .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  transactions: (json['transactions'] as List<dynamic>)
      .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  budgets: (json['budgets'] as List<dynamic>)
      .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  smartRules: (json['smartRules'] as List<dynamic>)
      .map((e) => SmartRuleModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  exportedAt: DateTime.parse(json['exportedAt'] as String),
  version: json['version'] as String? ?? '1.0.0',
);

Map<String, dynamic> _$ExportBundleToJson(ExportBundle instance) =>
    <String, dynamic>{
      'wallets': instance.wallets,
      'categories': instance.categories,
      'transactions': instance.transactions,
      'budgets': instance.budgets,
      'smartRules': instance.smartRules,
      'exportedAt': instance.exportedAt.toIso8601String(),
      'version': instance.version,
    };

ImportResult _$ImportResultFromJson(Map<String, dynamic> json) => ImportResult(
  insertedCounts: Map<String, int>.from(json['insertedCounts'] as Map),
  warnings: (json['warnings'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  hasErrors: json['hasErrors'] as bool? ?? false,
);

Map<String, dynamic> _$ImportResultToJson(ImportResult instance) =>
    <String, dynamic>{
      'insertedCounts': instance.insertedCounts,
      'warnings': instance.warnings,
      'hasErrors': instance.hasErrors,
    };
