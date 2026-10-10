import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../domain/goal_model.dart';
import '../domain/goal_repository_interface.dart';

class GoalRepository implements GoalRepositoryInterface {
  final AppDatabase _db;

  GoalRepository(this._db);

  GoalModel _toModel(SavingGoalEntry entry) {
    return GoalModel(
      id: entry.id,
      name: entry.name,
      targetAmount: entry.targetAmount,
      currentAmount: entry.currentAmount,
      targetDate: entry.targetDate,
      walletId: entry.walletId,
      icon: entry.icon,
      color: entry.color,
      isCompleted: entry.isCompleted,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  @override
  Future<List<GoalModel>> getGoals() async {
    final entries = await _db.goalDao.getAllGoals();
    return entries.map(_toModel).toList();
  }

  @override
  Stream<List<GoalModel>> watchGoals() {
    return _db.goalDao.watchAllGoals().map((entries) => entries.map(_toModel).toList());
  }

  @override
  Future<GoalModel?> getGoalById(int id) async {
    final entry = await _db.goalDao.getGoalById(id);
    return entry != null ? _toModel(entry) : null;
  }

  @override
  Future<int> createGoal(GoalModel goal) {
    return _db.goalDao.insertGoal(
      SavingGoalsCompanion.insert(
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: Value(goal.currentAmount),
        targetDate: Value(goal.targetDate),
        walletId: Value(goal.walletId),
        icon: Value(goal.icon),
        color: Value(goal.color),
        isCompleted: Value(goal.isCompleted),
        createdAt: Value(goal.createdAt),
        updatedAt: Value(goal.updatedAt),
      ),
    );
  }

  @override
  Future<bool> updateGoal(GoalModel goal) {
    return _db.goalDao.updateGoal(
      SavingGoalEntry(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        targetDate: goal.targetDate,
        walletId: goal.walletId,
        icon: goal.icon,
        color: goal.color,
        isCompleted: goal.isCompleted,
        createdAt: goal.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> addFunds({required int goalId, required double amount}) async {
    final goal = await _db.goalDao.getGoalById(goalId);
    if (goal == null) return;
    final newAmount = goal.currentAmount + amount;
    final isCompleted = newAmount >= goal.targetAmount;
    await _db.goalDao.updateGoalAmount(
      id: goalId,
      newAmount: newAmount,
      isCompleted: isCompleted,
    );
  }

  @override
  Future<void> withdrawFunds({required int goalId, required double amount}) async {
    final goal = await _db.goalDao.getGoalById(goalId);
    if (goal == null) return;
    final newAmount = (goal.currentAmount - amount).clamp(0.0, double.infinity);
    final isCompleted = newAmount >= goal.targetAmount;
    await _db.goalDao.updateGoalAmount(
      id: goalId,
      newAmount: newAmount,
      isCompleted: isCompleted,
    );
  }

  @override
  Future<void> deleteGoal(int id) {
    return _db.goalDao.deleteGoal(id);
  }
}
