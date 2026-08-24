import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'indonesian_regex_parser.dart';
import 'naive_bayes_classifier.dart';
import 'parsed_transaction.dart';

/// Transaction text parser pipeline (Regex -> Naive Bayes):
///
/// 1. Level 1: [IndonesianRegexParser] — deterministic Indonesian
///    amount/wallet/category keyword rules.
/// 2. Level 2: [NaiveBayesClassifier] — fallback used only when the regex
///    finds no category. Its training labels match category keys exactly,
///    so results map 1:1 onto seeded categories.
class TextParserService {
  final NaiveBayesClassifier _mlClassifier = NaiveBayesClassifier();

  TextParserService();

  Future<ParsedTransaction> parseText({
    required String text,
    String? merchant,
  }) async {
    // 1. Level 1: Indonesian Regex & Rule Matcher
    var result = IndonesianRegexParser.parse(text);

    // Merchant propagation: an explicitly provided merchant wins over the
    // parser-extracted one so callers (OCR, share import) can inject it.
    if (merchant != null && merchant.trim().isNotEmpty) {
      result = result.copyWith(merchant: merchant.trim());
    }

    // 2. Level 2: Naive Bayes fallback when regex found no category.
    if (result.categoryKey == null) {
      final mlCategory = _mlClassifier.classify(text);
      if (mlCategory != null) {
        result = result.copyWith(
          categoryKey: mlCategory,
          confidence: (result.confidence + 0.25).clamp(0.0, 1.0),
        );
      }
    }

    return result;
  }

  /// Parses multiple transactions if user inputs a list or multi-line text
  /// e.g. "1. Makan siang 30rb gopay\n2. Parkir 5rb cash\n3. Pulsa 50rb dana"
  Future<List<ParsedTransaction>> parseBatchText({required String text}) async {
    final rawLines = text
        .split(RegExp(r'[\r\n;]+|\b(?:dan lalu|kemudian|serta)\b', caseSensitive: false))
        .map((l) => l.replaceAll(RegExp(r'^\s*(?:\d+[\.\)]\s*|[-*•]\s*)'), '').trim())
        .where((l) => l.isNotEmpty && l.length > 3)
        .toList();

    if (rawLines.isEmpty) {
      return [await parseText(text: text)];
    }

    final results = <ParsedTransaction>[];
    for (final line in rawLines) {
      final parsed = await parseText(text: line);
      if (parsed.hasAmount) {
        results.add(parsed);
      }
    }

    return results.isNotEmpty ? results : [await parseText(text: text)];
  }
}

final textParserServiceProvider = Provider<TextParserService>((ref) {
  return TextParserService();
});
