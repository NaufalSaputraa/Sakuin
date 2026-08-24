import 'dart:convert';
import '../../core/database/app_database.dart';
import '../../features/smart_rules/domain/smart_rule_model.dart';
import '../../features/smart_rules/domain/smart_rule_repository_interface.dart';

class SmartRuleLearningService {
  final AppDatabase _db;
  final SmartRuleRepositoryInterface _repository;

  SmartRuleLearningService(this._db, this._repository);

  Future<List<SmartRuleModel>> generateFromHistory({
    int minOccurrences = 3,
    double minConfidence = 0.8,
  }) async {
    final transactions = await _db.transactionDao.getByDateRange(
      DateTime.now().subtract(const Duration(days: 90)),
      DateTime.now(),
    );

    if (transactions.isEmpty) return [];

    // Group by merchant and category
    final merchantCategoryMap = <String, Map<int, int>>{};
    final merchantCount = <String, int>{};

    for (final tx in transactions) {
      // Fall back to title for legacy rows created before merchant
      // propagation was added.
      final rawMerchant =
          (tx.merchant != null && tx.merchant!.trim().isNotEmpty) ? tx.merchant! : tx.title;
      if (rawMerchant.trim().isEmpty) continue;
      if (tx.categoryId == null) continue;
      if (tx.transactionType != 'expense') continue;

      final merchant = rawMerchant.toLowerCase().trim();
      merchantCount[merchant] = (merchantCount[merchant] ?? 0) + 1;

      merchantCategoryMap[merchant] ??= {};
      merchantCategoryMap[merchant]![tx.categoryId!] =
          (merchantCategoryMap[merchant]![tx.categoryId!] ?? 0) + 1;
    }

    final generatedRules = <SmartRuleModel>[];
    final existingRules = await _repository.getActiveRules();
    final existingMerchants = <String>{};

    if (existingRules.isSuccess) {
      for (final rule in existingRules.valueOrNull ?? []) {
        for (final condition in rule.conditions) {
          if (condition.field == RuleField.merchant) {
            existingMerchants.add(condition.value.toLowerCase());
          }
        }
      }
    }

    for (final entry in merchantCategoryMap.entries) {
      final merchant = entry.key;
      final categoryCounts = entry.value;
      final totalCount = merchantCount[merchant] ?? 0;

      if (totalCount < minOccurrences) continue;
      if (existingMerchants.contains(merchant)) continue;

      // Find most frequent category
      final topCategoryEntry = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final topCategoryKey = topCategoryEntry.key;
      final topCategoryValue = topCategoryEntry.value;

      final confidence = topCategoryValue / totalCount;
      if (confidence < minConfidence) continue;

      // Create rule
      final rule = SmartRuleModel(
        id: 0,
        name: 'Auto: $merchant → ${_getCategoryName(topCategoryKey)}',
        isActive: true,
        conditions: [
          RuleCondition(
            field: RuleField.merchant,
            operator: RuleOperator.contains,
            value: merchant,
          ),
        ],
        action: RuleAction(
          type: RuleActionType.categorize,
          value: jsonEncode({'categoryId': topCategoryKey}),
        ),
        priority: 999,
        createdAt: DateTime.now(),
      );

      generatedRules.add(rule);
    }

    // Save generated rules
    for (final rule in generatedRules) {
      await _repository.save(rule);
    }

    return generatedRules;
  }

  String _getCategoryName(int categoryId) {
    // This would ideally fetch from category repository
    // For now return a placeholder
    return 'Category $categoryId';
  }
}