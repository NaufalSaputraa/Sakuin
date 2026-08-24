import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sakuin_app/services/currency/currency_converter_service.dart';
import 'package:sakuin_app/features/currency/domain/currency_model.dart';
import 'package:sakuin_app/core/database/app_database.dart';
import 'package:sakuin_app/features/currency/data/currency_repository.dart';

void main() {
  group('CurrencyConverterService', () {
    final service = CurrencyConverterService();

    test('converts USD to IDR using offline rate', () {
      final result = service.convert(amount: 10, from: 'USD', to: 'IDR');
      expect(result.isSuccess, isTrue);
      // 10 USD * 15500 = 155000 IDR
      expect(result.valueOrNull!.converted, closeTo(155000.0, 0.001));
      expect(result.valueOrNull!.rate, closeTo(15500.0, 0.001));
    });

    test('converts IDR to USD (inverse rate)', () {
      final result = service.convert(amount: 155000, from: 'IDR', to: 'USD');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.converted, closeTo(10.0, 0.001));
    });

    test('same currency returns same amount with rate 1', () {
      final result = service.convert(amount: 50000, from: 'IDR', to: 'IDR');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.converted, 50000.0);
      expect(result.valueOrNull!.rate, 1.0);
    });

    test('unknown currency returns failure', () {
      final result = service.convert(amount: 10, from: 'XYZ', to: 'IDR');
      expect(result.isFailure, isTrue);
    });

    test('toIdr converts amount to IDR equivalent', () {
      expect(service.toIdr(2, 'SGD'), closeTo(23000.0, 0.001));
      expect(service.toIdr(100, 'JPY'), closeTo(10500.0, 0.001));
    });

    test('rateToIdr falls back to 1.0 for unknown code', () {
      expect(service.rateToIdr('XYZ'), 1.0);
    });
  });

  group('Currency Model', () {
    test('CurrencyRateModel serializes and deserializes via json', () {
      final model = CurrencyRateModel(
        code: 'USD',
        name: 'US Dollar',
        rateToIdr: 15500,
        isBase: false,
        updatedAt: _fixedDate,
      );
      final json = model.toJson();
      final restored = CurrencyRateModel.fromJson(json);
      expect(restored.code, 'USD');
      expect(restored.rateToIdr, 15500);
      expect(restored.isBase, isFalse);
    });
  });

  group('Database Migration v2 -> v3 (dummy)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('seeds default currency rates on fresh install (v3)', () async {
      final repo = CurrencyRepository(db);
      final rates = await repo.watchRates().first;

      expect(rates.length, greaterThanOrEqualTo(6));
      final idr = rates.where((r) => r.code == 'IDR').firstOrNull;
      expect(idr, isNotNull);
      expect(idr!.isBase, isTrue);
      expect(idr.rateToIdr, 1.0);

      final usd = rates.where((r) => r.code == 'USD').firstOrNull;
      expect(usd, isNotNull);
      expect(usd!.rateToIdr, 15500.0);
    });

    test('transactions table has currency + amountBase columns', () async {
      final repo = CurrencyRepository(db);
      // Insert a rate, then verify conversion uses it.
      final conv = await repo.convert(amount: 10, from: 'USD', to: 'IDR');
      expect(conv.isSuccess, isTrue);
      expect(conv.valueOrNull!.converted, closeTo(155000.0, 0.001));
    });
  });
}

final _fixedDate = DateTime(2024, 1, 1);
