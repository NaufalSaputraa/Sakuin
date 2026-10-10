import 'goal_model.dart';

abstract class GoalRepositoryInterface {
  Future<List<GoalModel>> getGoals();
  Stream<List<GoalModel>> watchGoals();
  Future<GoalModel?> getGoalById(int id);
  Future<int> createGoal(GoalModel goal);
  Future<bool> updateGoal(GoalModel goal);
  Future<void> addFunds({required int goalId, required double amount});
  Future<void> withdrawFunds({required int goalId, required double amount});
  Future<void> deleteGoal(int id);
}
