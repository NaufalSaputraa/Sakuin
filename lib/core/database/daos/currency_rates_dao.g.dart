// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_rates_dao.dart';

// ignore_for_file: type=lint
mixin _$CurrencyRatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CurrencyRatesTable get currencyRates => attachedDatabase.currencyRates;
  CurrencyRatesDaoManager get managers => CurrencyRatesDaoManager(this);
}

class CurrencyRatesDaoManager {
  final _$CurrencyRatesDaoMixin _db;
  CurrencyRatesDaoManager(this._db);
  $$CurrencyRatesTableTableManager get currencyRates =>
      $$CurrencyRatesTableTableManager(_db.attachedDatabase, _db.currencyRates);
}
