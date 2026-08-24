import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/currency_repository.dart';
import '../domain/currency_model.dart';
import '../domain/currency_repository_interface.dart';
import '../../../services/currency/currency_converter_service.dart';

final currencyRepositoryProvider = Provider<CurrencyRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return CurrencyRepository(db);
});

/// Stream of all offline currency rates.
final currencyRatesProvider = StreamProvider.autoDispose<List<CurrencyRateModel>>((ref) {
  final repo = ref.watch(currencyRepositoryProvider);
  return repo.watchRates();
});

/// Offline converter service built from the DB rates (single rate source).
///
/// Watching [currencyRatesProvider] keeps the service in sync with
/// user-edited rates so consumers (e.g. quick entry) see edits immediately.
/// Falls back to static offline defaults while the DB is loading or empty.
final converterProvider = Provider<CurrencyConverterService>((ref) {
  final rates = ref.watch(currencyRatesProvider).value;
  if (rates == null || rates.isEmpty) {
    return CurrencyConverterService();
  }
  return CurrencyConverterService(rates);
});

/// Currently selected currency for new transactions (quick entry sheet).
/// Riverpod 3 removed [StateProvider]; use a [Notifier] instead.
class SelectedCurrencyNotifier extends Notifier<String> {
  @override
  String build() => 'IDR';

  void set(String code) => state = code;
}

final selectedCurrencyProvider =
    NotifierProvider<SelectedCurrencyNotifier, String>(
  () => SelectedCurrencyNotifier(),
);
