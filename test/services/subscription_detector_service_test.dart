import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/features/transactions/domain/transaction_model.dart';
import 'package:sakuin_app/services/subscription_detector_service.dart';

void main() {
  group('SubscriptionDetectorService', () {
    late SubscriptionDetectorService detector;

    setUp(() {
      detector = SubscriptionDetectorService();
    });

    TransactionModel createTx({
      required int id,
      required String merchant,
      required double amount,
      required DateTime date,
    }) {
      return TransactionModel(
        id: id,
        walletId: 1,
        amount: amount,
        transactionType: TransactionType.expense,
        title: merchant,
        merchant: merchant,
        currency: 'IDR',
        amountBase: amount,
        transactionDate: date,
        createdAt: date,
        updatedAt: date,
      );
    }

    test('detects monthly subscription across February (28-day gap) and 31-day months', () {
      final txs = [
        createTx(id: 1, merchant: 'Netflix', amount: 186000, date: DateTime(2026, 1, 31)),
        createTx(id: 2, merchant: 'Netflix', amount: 186000, date: DateTime(2026, 2, 28)), // 28 days gap
        createTx(id: 3, merchant: 'Netflix', amount: 186000, date: DateTime(2026, 3, 31)), // 31 days gap
      ];

      final results = detector.detect(txs);
      expect(results.length, 1);

      final netflix = results.first;
      expect(netflix.merchant, 'Netflix');
      expect(netflix.occurrenceCount, 3);
      expect(netflix.amount, 186000);
      expect(netflix.confidence, greaterThan(0.7));

      // Next charge estimate after March 31 clamps to April 30
      expect(netflix.nextChargeEstimate.year, 2026);
      expect(netflix.nextChargeEstimate.month, 4);
      expect(netflix.nextChargeEstimate.day, 30);
    });

    test('ignores non-recurring random interval transactions', () {
      final txs = [
        createTx(id: 1, merchant: 'Warung Makan', amount: 35000, date: DateTime(2026, 1, 5)),
        createTx(id: 2, merchant: 'Warung Makan', amount: 35000, date: DateTime(2026, 1, 12)), // 7 days
        createTx(id: 3, merchant: 'Warung Makan', amount: 35000, date: DateTime(2026, 2, 20)), // 39 days
      ];

      final results = detector.detect(txs);
      expect(results.isEmpty, isTrue);
    });
  });
}
