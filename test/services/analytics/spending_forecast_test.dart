import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/features/home/domain/spending_forecast.dart';

void main() {
  group('SpendingForecast & Predictive Runway', () {
    test('healthy budget and spending yields Grade A and safe runway', () {
      final forecast = computeForecast(
        balance: 5000000,
        budgetLimit: 3000000,
        spentSoFar: 500000,
        daysElapsed: 10,
        daysInPeriod: 30,
        topCategory: 'Food',
        topCategoryAmount: 200000,
      );

      expect(forecast.dailyAvg, 50000);
      expect(forecast.forecastSpend, 1500000);
      expect(forecast.willBustBudget, isFalse);
      expect(forecast.runwayDays, 100);
      expect(forecast.survivesUntilMonthEnd, isTrue);
      expect(forecast.healthScore, greaterThanOrEqualTo(85));
      expect(forecast.healthGrade, 'A');
    });

    test('overspending busting budget yields warning and lower grade', () {
      final forecast = computeForecast(
        balance: 800000,
        budgetLimit: 2000000,
        spentSoFar: 2500000,
        daysElapsed: 15,
        daysInPeriod: 30,
        topCategory: 'Entertainment',
        topCategoryAmount: 1800000,
      );

      expect(forecast.willBustBudget, isTrue);
      expect(forecast.survivesUntilMonthEnd, isFalse);
      expect(forecast.runwayDays, lessThan(15));
      expect(forecast.healthScore, lessThan(70));
      expect(forecast.suggestedDailyPace, greaterThan(0));
    });

    test('zero balance yields 0 runway and low health grade', () {
      final forecast = computeForecast(
        balance: 0,
        budgetLimit: 2000000,
        spentSoFar: 500000,
        daysElapsed: 5,
        daysInPeriod: 30,
        topCategory: 'Transport',
        topCategoryAmount: 300000,
      );

      expect(forecast.runwayDays, 0);
      expect(forecast.healthGrade, anyOf('C', 'D'));
    });
  });
}
