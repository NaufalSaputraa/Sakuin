import '../../../core/utils/result.dart';
import '../domain/currency_model.dart';
import '../../../services/currency/currency_converter_service.dart';

abstract class CurrencyRepositoryInterface {
  /// Stream of all currency rates (for UI lists / settings).
  Stream<List<CurrencyRateModel>> watchRates();

  /// Get a single rate by currency code.
  Future<Result<CurrencyRateModel, AppError>> getRate(String code);

  /// Insert or update a currency rate (user-editable offline rates).
  Future<Result<bool, AppError>> upsertRate(CurrencyRateModel rate);

  /// Convert [amount] from [from] to [to] using offline rates.
  Future<Result<ConversionResult, AppError>> convert({
    required double amount,
    required String from,
    required String to,
  });
}
