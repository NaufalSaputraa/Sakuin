import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets, Categories, Transactions])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Stream<List<BudgetEntry>> watchActiveBudgets() {
    return (select(budgets)..where((t) => t.isActive.equals(true))).watch();
  }

  Future<List<BudgetEntry>> getActiveBudgets() {
    return (select(budgets)..where((t) => t.isActive.equals(true))).get();
  }

  Future<int> insertBudget(BudgetsCompanion companion) {
    return into(budgets).insert(companion);
  }

  Future<bool> updateBudget(BudgetEntry entry) {
    return update(budgets).replace(entry);
  }

  Future<int> deleteBudget(int id) {
    return (delete(budgets)..where((t) => t.id.equals(id))).go();
  }
}
