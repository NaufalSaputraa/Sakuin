import '../../core/database/daos/currency_rates_dao.dart';
import 'currency_converter_service.dart';

/// Single authority for computing a transaction's base-currency (IDR)
/// amount.
///
/// Reads the user-editable rate from [CurrencyRatesDao] first and falls
/// back to the static offline default rate when the code is missing from
/// the DB or the read fails.
class CurrencyRateSource {
  const CurrencyRateSource._();

  /// Compute [amount] expressed in [currency] as its IDR (base) equivalent.
  ///
  /// Returns [amount] unchanged when the currency is unknown (safe
  /// fallback).
  static Future<double> computeAmountBase(
    double amount,
    String currency,
    CurrencyRatesDao ratesDao,
  ) async {
    if (currency == 'IDR') return amount;
    try {
      final entry = await ratesDao.getByCode(currency);
      if (entry != null) return amount * entry.rateToIdr;
    } catch (_) {
      // Fall through to static offline default below.
    }
    final match = CurrencyConverterService.defaultRates
        .where((r) => r.code == currency)
        .firstOrNull;
    return match == null ? amount : amount * match.rateToIdr;
  }
}
