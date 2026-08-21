import '../../features/smart_rules/domain/smart_rule_model.dart';
import '../../features/smart_rules/domain/smart_rule_repository_interface.dart';

class RuleEvaluationResult {
  final RuleAction? action;
  final SmartRuleModel? matchedRule;

  const RuleEvaluationResult({
    this.action,
    this.matchedRule,
  });

  bool get hasMatch => action != null;
}

class SmartRuleEvaluatorService {
  final SmartRuleRepositoryInterface _repository;

  SmartRuleEvaluatorService(this._repository);

  Future<RuleEvaluationResult> evaluate({
    required String merchant,
    required String title,
    required double amount,
    required int? categoryId,
  }) async {
    final rulesResult = await _repository.getActiveRules();

    if (rulesResult.isFailure) {
      return const RuleEvaluationResult();
    }

    final rules = rulesResult.valueOrNull ?? [];

    for (final rule in rules) {
      if (_matchesAllConditions(
        rule: rule,
        merchant: merchant,
        title: title,
        amount: amount,
        categoryId: categoryId,
      )) {
        return RuleEvaluationResult(
          action: rule.action,
          matchedRule: rule,
        );
      }
    }

    return const RuleEvaluationResult();
  }

  bool _matchesAllConditions({
    required SmartRuleModel rule,
    required String merchant,
    required String title,
    required double amount,
    required int? categoryId,
  }) {
    for (final condition in rule.conditions) {
      if (!_matchesCondition(
        condition: condition,
        merchant: merchant,
        title: title,
        amount: amount,
        categoryId: categoryId,
      )) {
        return false;
      }
    }
    return true;
  }

  bool _matchesCondition({
    required RuleCondition condition,
    required String merchant,
    required String title,
    required double amount,
    required int? categoryId,
  }) {
    final fieldValue = _getFieldValue(
      field: condition.field,
      merchant: merchant,
      title: title,
      amount: amount,
      categoryId: categoryId,
    );

    if (fieldValue == null) return false;

    switch (condition.operator) {
      case RuleOperator.contains:
        return fieldValue.toString().toLowerCase().contains(condition.value.toLowerCase());
      case RuleOperator.equals:
        return fieldValue.toString().toLowerCase() == condition.value.toLowerCase();
      case RuleOperator.gt:
        return _compareNumbers(fieldValue, condition.value) > 0;
      case RuleOperator.lt:
        return _compareNumbers(fieldValue, condition.value) < 0;
      case RuleOperator.gte:
        return _compareNumbers(fieldValue, condition.value) >= 0;
      case RuleOperator.lte:
        return _compareNumbers(fieldValue, condition.value) <= 0;
    }
  }

  dynamic _getFieldValue({
    required RuleField field,
    required String merchant,
    required String title,
    required double amount,
    required int? categoryId,
  }) {
    switch (field) {
      case RuleField.merchant:
        return merchant;
      case RuleField.title:
        return title;
      case RuleField.amount:
        return amount;
      case RuleField.categoryId:
        return categoryId;
    }
  }

  int _compareNumbers(dynamic a, dynamic b) {
    final numA = num.tryParse(a.toString());
    final numB = num.tryParse(b.toString());
    if (numA == null || numB == null) return 0;
    return numA.compareTo(numB);
  }
}