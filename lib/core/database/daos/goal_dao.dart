import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [SavingGoals])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Stream<List<SavingGoalEntry>> watchAllGoals() {
    return (select(savingGoals)
          ..orderBy([
            (t) => OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<SavingGoalEntry>> getAllGoals() {
    return (select(savingGoals)
          ..orderBy([
            (t) => OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<SavingGoalEntry?> getGoalById(int id) {
    return (select(savingGoals)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertGoal(SavingGoalsCompanion companion) {
    return into(savingGoals).insert(companion);
  }

  Future<bool> updateGoal(SavingGoalEntry entry) {
    return update(savingGoals).replace(entry);
  }

  Future<int> updateGoalAmount({
    required int id,
    required double newAmount,
    required bool isCompleted,
  }) {
    return (update(savingGoals)..where((t) => t.id.equals(id))).write(
      SavingGoalsCompanion(
        currentAmount: Value(newAmount),
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteGoal(int id) {
    return (delete(savingGoals)..where((t) => t.id.equals(id))).go();
  }
}
