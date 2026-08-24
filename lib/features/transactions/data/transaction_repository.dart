import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/result.dart';
import '../../currency/data/currency_repository.dart';
import '../../currency/domain/currency_repository_interface.dart';
import '../../../services/currency/currency_converter_service.dart';
import '../domain/transaction_model.dart';
import '../domain/transaction_repository_interface.dart';

class TransactionRepository implements TransactionRepositoryInterface {
  final AppDatabase _db;
  final CurrencyRepositoryInterface _currencyRepo;

  TransactionRepository(this._db, [CurrencyRepositoryInterface? currencyRepo])
      : _currencyRepo = currencyRepo ?? CurrencyRepository(_db);

  TransactionModel _toDomain(TransactionEntry entry) {
    return TransactionModel(
      id: entry.id,
      walletId: entry.walletId,
      categoryId: entry.categoryId,
      amount: entry.amount,
      transactionType: TransactionType.fromString(entry.transactionType),
      title: entry.title,
      description: entry.description,
      merchant: entry.merchant,
      sourceInput: entry.sourceInput,
      rawInput: entry.rawInput,
      transferToWalletId: entry.transferToWalletId,
      transactionDate: entry.transactionDate,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      currency: entry.currency,
      amountBase: entry.amountBase,
    );
  }

  @override
  Stream<List<TransactionModel>> watchRecent({int limit = 20}) {
    return _db.transactionDao.watchRecent(limit: limit).map((list) => list.map(_toDomain).toList());
  }

  @override
  Stream<List<TransactionModel>> watchByWallet(int walletId) {
    return _db.transactionDao.watchByWallet(walletId).map((list) => list.map(_toDomain).toList());
  }

  @override
  Stream<List<TransactionModel>> watchByDateRange(DateTime start, DateTime end) {
    return _db.transactionDao.watchByDateRange(start, end).map((list) => list.map(_toDomain).toList());
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final list = await _db.transactionDao.getByDateRange(start, end);
      return Success(list.map(_toDomain).toList());
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Stream<double> watchTotalIncomeForMonth(DateTime month) {
    return _db.transactionDao.watchTotalIncomeForMonth(month);
  }

  @override
  Stream<double> watchTotalExpenseForMonth(DateTime month) {
    return _db.transactionDao.watchTotalExpenseForMonth(month);
  }

  @override
  Future<Result<int, AppError>> createTransaction({
    required int walletId,
    int? categoryId,
    required double amount,
    required TransactionType transactionType,
    required String title,
    String? description,
    String? merchant,
    String sourceInput = 'manual',
    String? rawInput,
    int? transferToWalletId,
    DateTime? transactionDate,
    String currency = 'IDR',
  }) async {
    try {
      // Compute equivalent amount in IDR (base) using offline rates.
      final amountBase = await _computeAmountBase(amount, currency);

      final id = await _db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          walletId: walletId,
          categoryId: Value(categoryId),
          amount: amount,
          transactionType: transactionType.toDbString(),
          title: title,
          description: Value(description),
          merchant: Value(merchant),
          sourceInput: Value(sourceInput),
          rawInput: Value(rawInput),
          transferToWalletId: Value(transferToWalletId),
          currency: Value(currency),
          amountBase: Value(amountBase),
          transactionDate: Value(transactionDate ?? DateTime.now()),
        ),
      );
      return Success(id);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  /// Compute amountBase by reading the rate from the currency DAO.
  /// Falls back to the static default rate if the code is not in the DB.
  Future<double> _computeAmountBase(double amount, String currency) async {
    if (currency == 'IDR') return amount;
    final rate = await _currencyRepo.getRate(currency);
    if (rate.isSuccess) {
      return amount * rate.valueOrNull!.rateToIdr;
    }
    // Fallback to static offline default.
    return _fallbackAmountBase(amount, currency);
  }

  double _fallbackAmountBase(double amount, String currency) {
    if (currency == 'IDR') return amount;
    final defaults = CurrencyConverterService.defaultRates;
    final match = defaults.where((r) => r.code == currency).firstOrNull;
    return match == null ? amount : amount * match.rateToIdr;
  }

  @override
  Future<Result<int, AppError>> deleteTransaction(int id) async {
    try {
      final count = await _db.transactionDao.deleteTransaction(id);
      return Success(count);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }
}
