import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/result.dart';
import '../domain/budget_model.dart';
import '../domain/budget_repository_interface.dart';

class BudgetRepository implements BudgetRepositoryInterface {
  final AppDatabase _db;

  BudgetRepository(this._db);

  BudgetModel _toDomain(BudgetEntry entry) {
    return BudgetModel(
      id: entry.id,
      name: entry.name,
      budgetType: BudgetType.fromString(entry.budgetType),
      amount: entry.amount,
      period: entry.period,
      categoryId: entry.categoryId,
      walletId: entry.walletId,
      startDate: entry.startDate,
      endDate: entry.endDate,
      isActive: entry.isActive,
      createdAt: entry.createdAt,
    );
  }

  @override
  Stream<List<BudgetModel>> watchActiveBudgets() {
    return _db.budgetDao.watchActiveBudgets().map((list) => list.map(_toDomain).toList());
  }

  @override
  Future<Result<List<BudgetModel>, AppError>> getActiveBudgets() async {
    try {
      final list = await _db.budgetDao.getActiveBudgets();
      return Success(list.map(_toDomain).toList());
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<int, AppError>> createBudget({
    required String name,
    required BudgetType budgetType,
    required double amount,
    String period = 'monthly',
    int? categoryId,
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final id = await _db.budgetDao.insertBudget(
        BudgetsCompanion.insert(
          name: name,
          budgetType: budgetType.toDbString(),
          amount: amount,
          period: Value(period),
          categoryId: Value(categoryId),
          walletId: Value(walletId),
          startDate: Value(startDate ?? DateTime.now()),
          endDate: Value(endDate),
        ),
      );
      return Success(id);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> updateBudget(BudgetModel budget) async {
    try {
      final entry = BudgetEntry(
        id: budget.id,
        name: budget.name,
        budgetType: budget.budgetType.toDbString(),
        amount: budget.amount,
        period: budget.period,
        categoryId: budget.categoryId,
        walletId: budget.walletId,
        startDate: budget.startDate,
        endDate: budget.endDate,
        isActive: budget.isActive,
        createdAt: budget.createdAt,
      );
      final updated = await _db.budgetDao.updateBudget(entry);
      return Success(updated);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }

  @override
  Future<Result<int, AppError>> deleteBudget(int id) async {
    try {
      final count = await _db.budgetDao.deleteBudget(id);
      return Success(count);
    } catch (e) {
      return Failure(AppError.database(e.toString()));
    }
  }
}
