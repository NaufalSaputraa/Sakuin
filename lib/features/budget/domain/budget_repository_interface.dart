import '../../../core/utils/result.dart';
import 'budget_model.dart';

abstract class BudgetRepositoryInterface {
  Stream<List<BudgetModel>> watchActiveBudgets();
  Future<Result<List<BudgetModel>, AppError>> getActiveBudgets();
  Future<Result<int, AppError>> createBudget({
    required String name,
    required BudgetType budgetType,
    required double amount,
    String period = 'monthly',
    int? categoryId,
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Result<bool, AppError>> updateBudget(BudgetModel budget);
  Future<Result<int, AppError>> deleteBudget(int id);
}
