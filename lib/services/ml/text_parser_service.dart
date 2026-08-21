import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/categories/domain/category_model.dart';
import '../../features/wallets/domain/wallet_model.dart';
import '../../features/smart_rules/domain/smart_rule_model.dart';
import '../../features/smart_rules/providers/smart_rule_providers.dart';
import 'indonesian_regex_parser.dart';
import 'naive_bayes_classifier.dart';
import 'parsed_transaction.dart';
import 'smart_rule_evaluator_service.dart';

class TextParserService {
  final NaiveBayesClassifier _mlClassifier = NaiveBayesClassifier();
  final SmartRuleEvaluatorService? _ruleEvaluator;

  TextParserService({SmartRuleEvaluatorService? ruleEvaluator})
      : _ruleEvaluator = ruleEvaluator;

  Future<ParsedTransaction> parseText({
    required String text,
    required List<WalletModel> availableWallets,
    required List<CategoryModel> availableCategories,
    String? merchant,
    double? amount,
    int? categoryId,
  }) async {
    // 1. Level 1: Indonesian Regex & Rule Matcher
    var result = IndonesianRegexParser.parse(text);

    // 2. Level 2: Machine Learning Naive Bayes NLP Fallback
    if (result.categoryKey == null || result.categoryKey == 'other_expense') {
      final mlCategory = _mlClassifier.classify(text);
      if (mlCategory != null) {
        result = result.copyWith(
          categoryKey: mlCategory,
          confidence: (result.confidence + 0.25).clamp(0.0, 1.0),
        );
      }
    }

    // 3. Level 3: Smart Rules Engine (if available)
    if (_ruleEvaluator != null && merchant != null && amount != null) {
      final evaluator = _ruleEvaluator!;
      final evaluation = await evaluator.evaluate(
        merchant: merchant,
        title: text,
        amount: amount,
        categoryId: categoryId,
      );

      if (evaluation.hasMatch && evaluation.action != null) {
        final action = evaluation.action!;
        if (action.type == RuleActionType.categorize) {
          final actionData = _parseActionValue(action.value);
          final categoryId = actionData['categoryId'] as int?;
          if (categoryId != null) {
            final category = availableCategories
                .where((c) => c.id == categoryId)
                .firstOrNull;
            if (category != null) {
              result = result.copyWith(
                categoryKey: category.key,
                confidence: (result.confidence + 0.3).clamp(0.0, 1.0),
              );
            }
          }
        } else if (action.type == RuleActionType.wallet) {
          final actionData = _parseActionValue(action.value);
          final walletProvider = actionData['walletProvider'] as String?;
          if (walletProvider != null) {
            result = result.copyWith(walletProvider: walletProvider);
          }
        }
      }
    }

    return result;
  }

  Map<String, dynamic> _parseActionValue(String value) {
    try {
      return Map<String, dynamic>.from(jsonDecode(value));
    } catch (_) {
      return {};
    }
  }

  /// Parses multiple transactions if user inputs a list or multi-line text
  /// e.g. "1. Makan siang 30rb gopay\n2. Parkir 5rb cash\n3. Pulsa 50rb dana"
  Future<List<ParsedTransaction>> parseBatchText({
    required String text,
    required List<WalletModel> availableWallets,
    required List<CategoryModel> availableCategories,
  }) async {
    final rawLines = text
        .split(RegExp(r'[\r\n;]+|\b(?:dan lalu|kemudian|serta)\b', caseSensitive: false))
        .map((l) => l.replaceAll(RegExp(r'^\s*(?:\d+[\.\)]\s*|[-*•]\s*)'), '').trim())
        .where((l) => l.isNotEmpty && l.length > 3)
        .toList();

    if (rawLines.isEmpty) {
      return [await parseText(text: text, availableWallets: availableWallets, availableCategories: availableCategories)];
    }

    final results = <ParsedTransaction>[];
    for (final line in rawLines) {
      final parsed = await parseText(
        text: line,
        availableWallets: availableWallets,
        availableCategories: availableCategories,
      );
      if (parsed.hasAmount) {
        results.add(parsed);
      }
    }

    return results.isNotEmpty
        ? results
        : [await parseText(text: text, availableWallets: availableWallets, availableCategories: availableCategories)];
  }
}

final textParserServiceProvider = Provider<TextParserService>((ref) {
  final evaluator = ref.watch(smartRuleEvaluatorServiceProvider);
  return TextParserService(ruleEvaluator: evaluator);
});