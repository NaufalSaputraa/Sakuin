import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'currency_rates_dao.g.dart';

@DriftAccessor(tables: [CurrencyRates])
class CurrencyRatesDao extends DatabaseAccessor<AppDatabase> with _$CurrencyRatesDaoMixin {
  CurrencyRatesDao(super.db);

  /// Watch all currency rates ordered by base first, then code.
  Stream<List<CurrencyRatesData>> watchAll() {
    return (select(currencyRates)
          ..orderBy([
            (t) => OrderingTerm(expression: t.isBase, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.code),
          ]))
        .watch();
  }

  /// Get a single rate by its currency code.
  Future<CurrencyRatesData?> getByCode(String code) {
    return (select(currencyRates)..where((t) => t.code.equals(code))).getSingleOrNull();
  }

  /// Insert a new currency rate.
  Future<int> insertRate(CurrencyRatesCompanion companion) {
    return into(currencyRates).insert(companion);
  }

  /// Update an existing currency rate.
  Future<bool> updateRate(CurrencyRatesCompanion companion) {
    return update(currencyRates).replace(companion);
  }

  /// Insert or update a currency rate (conflict on unique code).
  Future<int> upsertRate(CurrencyRatesCompanion companion) {
    return into(currencyRates).insertOnConflictUpdate(companion);
  }
}
