import '../../features/currency/domain/currency_model.dart';
import '../../core/utils/result.dart';

/// Structured result of a currency conversion (no raw Maps).
class ConversionResult {
  final double amount; // original amount
  final String from; // source currency code
  final String to; // target currency code
  final double rate; // from -> to rate
  final double converted; // converted amount in target currency

  const ConversionResult({
    required this.amount,
    required this.from,
    required this.to,
    required this.rate,
    required this.converted,
  });
}

/// Offline currency converter.
///
/// Uses a static table of exchange rates relative to IDR (base currency).
/// Rates are offline-only (no network). The service is pure and returns
/// structured [ConversionResult] / [Result] types — never raw Maps.
class CurrencyConverterService {
  /// Static offline seed rates (1 unit of currency = rateToIdr IDR).
  static final List<CurrencyRateModel> defaultRates = [
    CurrencyRateModel(
      code: 'IDR',
      name: 'Indonesian Rupiah',
      rateToIdr: 1.0,
      isBase: true,
      updatedAt: _epoch,
    ),
    CurrencyRateModel(
      code: 'USD',
      name: 'US Dollar',
      rateToIdr: 15500.0,
      isBase: false,
      updatedAt: _epoch,
    ),
    CurrencyRateModel(
      code: 'SGD',
      name: 'Singapore Dollar',
      rateToIdr: 11500.0,
      isBase: false,
      updatedAt: _epoch,
    ),
    CurrencyRateModel(
      code: 'EUR',
      name: 'Euro',
      rateToIdr: 16800.0,
      isBase: false,
      updatedAt: _epoch,
    ),
    CurrencyRateModel(
      code: 'JPY',
      name: 'Japanese Yen',
      rateToIdr: 105.0,
      isBase: false,
      updatedAt: _epoch,
    ),
    CurrencyRateModel(
      code: 'MYR',
      name: 'Malaysian Ringgit',
      rateToIdr: 3500.0,
      isBase: false,
      updatedAt: _epoch,
    ),
  ];

  static final DateTime _epoch = DateTime(2000);

  final List<CurrencyRateModel> _rates;

  CurrencyConverterService([List<CurrencyRateModel>? rates])
      : _rates = rates ?? defaultRates;

  CurrencyRateModel? _find(String code) =>
      _rates.where((r) => r.code == code).firstOrNull;

  /// Convert [amount] from [from] currency to [to] currency.
  /// Returns a [Result] wrapping a structured [ConversionResult].
  Result<ConversionResult, AppError> convert({
    required double amount,
    required String from,
    required String to,
  }) {
    if (from == to) {
      return Success(ConversionResult(
        amount: amount,
        from: from,
        to: to,
        rate: 1.0,
        converted: amount,
      ));
    }

    final fromRate = _find(from);
    final toRate = _find(to);

    if (fromRate == null) {
      return Failure(AppError.notFound('Currency "$from" not found'));
    }
    if (toRate == null) {
      return Failure(AppError.notFound('Currency "$to" not found'));
    }

    final rate = fromRate.rateToIdr / toRate.rateToIdr;
    final converted = amount * rate;

    return Success(ConversionResult(
      amount: amount,
      from: from,
      to: to,
      rate: rate,
      converted: converted,
    ));
  }

  /// Convert an [amount] in [from] currency into its IDR equivalent.
  /// Returns the original amount if the currency is unknown (safe fallback).
  double toIdr(double amount, String from) {
    final rate = _find(from);
    if (rate == null) return amount;
    return amount * rate.rateToIdr;
  }

  /// Get the rate-to-IDR for a currency (1.0 for unknown -> treated as IDR).
  double rateToIdr(String code) => _find(code)?.rateToIdr ?? 1.0;
}
