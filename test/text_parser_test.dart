import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/features/transactions/domain/transaction_model.dart';
import 'package:sakuin_app/services/ml/indonesian_regex_parser.dart';
import 'package:sakuin_app/services/ml/naive_bayes_classifier.dart';
import 'package:sakuin_app/services/ml/text_parser_service.dart';

void main() {
  group('IndonesianRegexParser Tests', () {
    test('parses "beli kopi 25rb gopay" correctly', () {
      final res = IndonesianRegexParser.parse('beli kopi 25rb gopay');
      expect(res.amount, 25000);
      expect(res.categoryKey, 'food');
      expect(res.walletProvider, 'gopay');
      expect(res.transactionType, TransactionType.expense);
      expect(res.title.toLowerCase(), contains('kopi'));
    });

    test('parses "gaji bulanan 7.5jt bca" as income correctly', () {
      final res = IndonesianRegexParser.parse('gaji bulanan 7.5jt bca');
      expect(res.amount, 7500000);
      expect(res.transactionType, TransactionType.income);
      expect(res.walletProvider, 'bank');
      expect(res.categoryKey, 'salary');
    });

    test('parses "isi pertalite 50k cash" as fuel expense', () {
      final res = IndonesianRegexParser.parse('isi pertalite 50k cash');
      expect(res.amount, 50000);
      expect(res.categoryKey, 'fuel');
      expect(res.walletProvider, 'physical');
      expect(res.transactionType, TransactionType.expense);
    });

    test('parses "bayar kos 1.5jt via dana" correctly', () {
      final res = IndonesianRegexParser.parse('bayar kos 1.5jt via dana');
      expect(res.amount, 1500000);
      expect(res.categoryKey, 'housing');
      expect(res.walletProvider, 'dana');
    });
  });

  group('NaiveBayesClassifier ML Tests', () {
    final classifier = NaiveBayesClassifier();

    test('classifies "angkringan nasi kucing" as food', () {
      final cat = classifier.classify('angkringan nasi kucing');
      expect(cat, 'food');
    });

    test('classifies "seblak ceker pedas" as food', () {
      final cat = classifier.classify('seblak ceker pedas');
      expect(cat, 'food');
    });

    test('classifies "token pln listrik" as bills', () {
      final cat = classifier.classify('token pln listrik');
      expect(cat, 'bills');
    });

    test('classifies "topup diamond mobile legends" as entertainment', () {
      final cat = classifier.classify('topup diamond mobile legends');
      expect(cat, 'entertainment');
    });
  });

  group('Batch TextParserService Tests', () {
    final parser = TextParserService();

    test('parses multi-line numbered list of expenses', () {
      const input = '''
        1. Makan siang 30rb gopay
        2. Parkir 5rb cash
        3. Pulsa 50rb dana
      ''';

      final list = parser.parseBatchText(
        text: input,
        availableWallets: [],
        availableCategories: [],
      );

      expect(list.length, 3);
      expect(list[0].amount, 30000);
      expect(list[0].walletProvider, 'gopay');
      expect(list[1].amount, 5000);
      expect(list[1].walletProvider, 'physical');
      expect(list[2].amount, 50000);
      expect(list[2].walletProvider, 'dana');
    });
  });
}
