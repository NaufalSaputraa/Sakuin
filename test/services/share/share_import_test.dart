import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/features/transactions/domain/transaction_model.dart';
import 'package:sakuin_app/services/ml/parsed_transaction.dart';
import 'package:sakuin_app/services/ml/text_parser_service.dart';

/// Share Import: verifies that texts shared from banking / e-wallet apps
/// (BCA, GoPay) are parsed into a [ParsedTransaction] via the existing
/// [TextParserService] pipeline (same one used by Smart Input).
void main() {
  final parser = TextParserService();

  group('Share Import — shared text parsing', () {
    test('BCA transfer text parses amount, wallet and type', () async {
      const sharedText = 'Transfer Rp 50.000 ke BCA';

      final result = await parser.parseText(
        text: sharedText,
        availableWallets: const [],
        availableCategories: [],
      );

      expect(result, isA<ParsedTransaction>());
      expect(result.amount, 50000);
      expect(result.walletProvider, 'bank');
      expect(result.transactionType, TransactionType.transfer);
      expect(result.rawInput, sharedText);
      expect(result.title, isNotEmpty);
    });

    test('GoPay shorthand text parses amount and wallet', () async {
      const sharedText = 'Kirim 50rb ke GoPay';

      final result = await parser.parseText(
        text: sharedText,
        availableWallets: const [],
        availableCategories: [],
      );

      expect(result.amount, 50000);
      expect(result.walletProvider, 'gopay');
      // Bare "kirim" is not a transfer verb in the regex parser
      // ("kirim uang" is), so this falls back to expense.
      expect(result.transactionType, TransactionType.expense);
      expect(result.rawInput, sharedText);
      expect(result.title, isNotEmpty);
    });

    test('BRI transfer text parses amount, bank wallet and type', () async {
      const sharedText = 'Transfer Rp 75.000 ke BRI';

      final result = await parser.parseText(
        text: sharedText,
        availableWallets: const [],
        availableCategories: [],
      );

      expect(result, isA<ParsedTransaction>());
      expect(result.amount, 75000);
      // "bri" is a keyword inside the 'bank' wallet entry
      // (indonesian_regex_parser), so the detected provider is 'bank'.
      expect(result.walletProvider, 'bank');
      expect(result.transactionType, TransactionType.transfer);
      expect(result.rawInput, sharedText);
      expect(result.title, contains('BRI'));
    });

    test('ShopeePay shorthand text parses amount and wallet', () async {
      const sharedText = 'Kirim 35rb ke ShopeePay';

      final result = await parser.parseText(
        text: sharedText,
        availableWallets: const [],
        availableCategories: [],
      );

      expect(result.amount, 35000);
      expect(result.walletProvider, 'shopeepay');
      // Same as GoPay: bare "kirim" falls back to expense.
      expect(result.transactionType, TransactionType.expense);
      expect(result.rawInput, sharedText);
      expect(result.title, isNotEmpty);
    });

    test('parsed result exposes helpers for sheet auto-fill', () async {
      const sharedText = 'Transfer Rp 50.000 ke BCA';

      final result = await parser.parseText(
        text: sharedText,
        availableWallets: const [],
        availableCategories: [],
      );

      expect(result.hasAmount, isTrue);
      expect(result.hasWallet, isTrue);
      expect(result.confidence, greaterThan(0));
    });
  });
}
