import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/features/goals/domain/goal_model.dart';

void main() {
  group('GoalModel Domain Tests', () {
    test('calculates progress and remaining amount correctly', () {
      final goal = GoalModel(
        id: 1,
        name: 'MacBook Pro',
        targetAmount: 20000000,
        currentAmount: 5000000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(goal.progress, 0.25);
      expect(goal.progressPercent, 25);
      expect(goal.remainingAmount, 15000000);
      expect(goal.daysRemaining, isNull);
      expect(goal.suggestedDailyPace, isNull);
    });

    test('calculates suggested daily pace when target date is set', () {
      final now = DateTime.now();
      final targetDate = now.add(const Duration(days: 50));

      final goal = GoalModel(
        id: 2,
        name: 'Liburan Jepang',
        targetAmount: 15000000,
        currentAmount: 5000000,
        targetDate: targetDate,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.remainingAmount, 10000000);
      expect(goal.daysRemaining, 50);
      expect(goal.suggestedDailyPace, 200000); // 10jt / 50 days = 200k/day
    });

    test('completed goal clamps progress to 1.0 and remaining amount to 0', () {
      final goal = GoalModel(
        id: 3,
        name: 'Dana Darurat',
        targetAmount: 10000000,
        currentAmount: 12000000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(goal.progress, 1.0);
      expect(goal.progressPercent, 100);
      expect(goal.remainingAmount, 0.0);
      expect(goal.suggestedDailyPace, isNull);
    });

    test('copyWith updates specified fields correctly', () {
      final goal = GoalModel(
        id: 1,
        name: 'Old Name',
        targetAmount: 5000000,
        currentAmount: 1000000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = goal.copyWith(
        name: 'New Name',
        currentAmount: 3000000,
        isCompleted: false,
      );

      expect(updated.name, 'New Name');
      expect(updated.currentAmount, 3000000);
      expect(updated.targetAmount, 5000000);
    });
  });
}
