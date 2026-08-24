import '../../../core/utils/result.dart';
import 'transaction_model.dart';

abstract class TransactionRepositoryInterface {
  Stream<List<TransactionModel>> watchRecent({int limit = 20});
  Stream<List<TransactionModel>> watchByWallet(int walletId);
  Stream<List<TransactionModel>> watchByDateRange(DateTime start, DateTime end);
  Future<Result<List<TransactionModel>, AppError>> getByDateRange(DateTime start, DateTime end);
  Stream<double> watchTotalIncomeForMonth(DateTime month);
  Stream<double> watchTotalExpenseForMonth(DateTime month);
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
  });
  Future<Result<int, AppError>> deleteTransaction(int id);
}
