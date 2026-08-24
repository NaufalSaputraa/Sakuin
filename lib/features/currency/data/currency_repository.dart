import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/result.dart';
import '../domain/currency_model.dart';
import '../domain/currency_repository_interface.dart';
import '../../../services/currency/currency_converter_service.dart';

class CurrencyRepository implements CurrencyRepositoryInterface {
  final AppDatabase _db;
  final CurrencyConverterService _converter;

  CurrencyRepository(this._db, [CurrencyConverterService? converter])
      : _converter = converter ?? CurrencyConverterService();

  CurrencyRateModel _toDomain(dynamic entry) => CurrencyRateModel.fromEntry(entry);

  @override
  Stream<List<CurrencyRateModel>> watchRates() {
    return _db.currencyRatesDao.watchAll().map((list) => list.map(_toDomain).toList());
  }

  @override
  Future<Result<CurrencyRateModel, AppError>> getRate(String code) async {
    try {
      final entry = await _db.currencyRatesDao.getByCode(code);
      if (entry == null) {
        return Failure(AppError.notFound('Currency rate "$code" not found'));
      }
      return Success(_toDomain(entry));
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> upsertRate(CurrencyRateModel rate) async {
    try {
      await _db.currencyRatesDao.upsertRate(
        // Companion.insert takes plain values for required columns (it wraps
        // them internally); only optional columns accept Value<T>.
        CurrencyRatesCompanion.insert(
          code: rate.code,
          name: rate.name,
          rateToIdr: rate.rateToIdr,
          isBase: Value(rate.isBase),
          updatedAt: Value(rate.updatedAt),
        ),
      );
      return const Success(true);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<ConversionResult, AppError>> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    // Prefer user-edited rates from DB; fall back to static offline defaults.
    try {
      final rates = await _db.currencyRatesDao.watchAll().first;
      final service = CurrencyConverterService(
        rates.map((e) => _toDomain(e)).toList(),
      );
      return service.convert(amount: amount, from: from, to: to);
    } catch (e) {
      // Fallback to static defaults if DB read fails.
      return _converter.convert(amount: amount, from: from, to: to);
    }
  }
}
