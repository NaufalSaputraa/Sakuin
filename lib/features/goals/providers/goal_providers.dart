import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../domain/goal_model.dart';
import '../domain/goal_repository_interface.dart';
import '../data/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return GoalRepository(db);
});

final watchGoalsProvider = StreamProvider.autoDispose<List<GoalModel>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.watchGoals();
});

class GoalNotifier extends AsyncNotifier<List<GoalModel>> {
  @override
  FutureOr<List<GoalModel>> build() async {
    final repo = ref.watch(goalRepositoryProvider);
    return repo.getGoals();
  }

  Future<void> createGoal(GoalModel goal) async {
    final repo = ref.read(goalRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.createGoal(goal);
      return repo.getGoals();
    });
  }

  Future<void> updateGoal(GoalModel goal) async {
    final repo = ref.read(goalRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.updateGoal(goal);
      return repo.getGoals();
    });
  }

  Future<void> addFunds({required int goalId, required double amount}) async {
    final repo = ref.read(goalRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.addFunds(goalId: goalId, amount: amount);
      return repo.getGoals();
    });
  }

  Future<void> withdrawFunds({required int goalId, required double amount}) async {
    final repo = ref.read(goalRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.withdrawFunds(goalId: goalId, amount: amount);
      return repo.getGoals();
    });
  }

  Future<void> deleteGoal(int id) async {
    final repo = ref.read(goalRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.deleteGoal(id);
      return repo.getGoals();
    });
  }
}

final goalNotifierProvider =
    AsyncNotifierProvider<GoalNotifier, List<GoalModel>>(() {
  return GoalNotifier();
});
