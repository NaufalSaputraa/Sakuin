import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/features/transactions/domain/transaction_model.dart';
import 'package:sakuin_app/services/ml/text_parser_service.dart';
import 'package:sakuin_app/services/voice/speech_service.dart';

void main() {
  group('Voice STT -> ParsedTransaction mapping', () {
    final parser = TextParserService();

    test('maps spoken "beli kopi 25rb gopay" to ParsedTransaction', () async {
      // Simulates a transcript produced by on-device STT being fed into the
      // shared text-parser pipeline (no microphone required for this unit test).
      const transcript = 'beli kopi 25rb gopay';
      final parsed = await parser.parseText(
        text: transcript,
        availableWallets: [],
        availableCategories: [],
      );

      expect(parsed.amount, 25000);
      expect(parsed.categoryKey, 'food');
      expect(parsed.walletProvider, 'gopay');
      expect(parsed.transactionType, TransactionType.expense);
      expect(parsed.hasAmount, isTrue);
    });

    test('maps spoken income "gaji bulanan 7.5jt" to income ParsedTransaction',
        () async {
      const transcript = 'gaji bulanan 7.5jt';
      final parsed = await parser.parseText(
        text: transcript,
        availableWallets: [],
        availableCategories: [],
      );

      expect(parsed.amount, 7500000);
      expect(parsed.transactionType, TransactionType.income);
    });

    test('maps spoken "bayar kos 1.5jt via dana" to housing/dana expense',
        () async {
      const transcript = 'bayar kos 1.5jt via dana';
      final parsed = await parser.parseText(
        text: transcript,
        availableWallets: [],
        availableCategories: [],
      );

      expect(parsed.amount, 1500000);
      expect(parsed.categoryKey, 'housing');
      expect(parsed.walletProvider, 'dana');
    });

    test('SpeechService can be instantiated (smoke test, no mic)', () {
      expect(SpeechService(), isA<SpeechService>());
      expect(SpeechService().isListening, isFalse);
    });
  });
}
