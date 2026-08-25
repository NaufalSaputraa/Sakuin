/// Pure, Flutter-free spending forecast model and computation.
///
/// Used by [AiSpendingRecommendationWidget] to project the end-of-period
/// balance and detect budget overruns. All math lives here so it can be unit
/// tested without any Flutter/widget dependencies.
library;

class SpendingForecast {
  final double projectedBalance;
  final double forecastSpend;
  final bool willBustBudget;
  final String? topCategory;
  final double topCategoryAmount;
  final int daysRemaining;
  final double dailyAvg;

  /// Active budget limit, or `null` when there is no budget.
  final double? budgetLimit;

  const SpendingForecast({
    required this.projectedBalance,
    required this.forecastSpend,
    required this.willBustBudget,
    this.topCategory,
    required this.topCategoryAmount,
    required this.daysRemaining,
    required this.dailyAvg,
    this.budgetLimit,
  });
}

/// Computes a [SpendingForecast] from raw inputs.
///
/// [budgetLimit] is `null` when there is no active budget — in that case
/// [willBustBudget] is always `false` (we still project the balance).
///
/// Formula:
/// - [dailyAvg] = [spentSoFar] / max([daysElapsed], 1)
/// - [forecastSpend] = [dailyAvg] * [daysInPeriod]
/// - [projectedBalance] = [balance] - [dailyAvg] * [daysRemaining]
/// - [willBustBudget] = [forecastSpend] > [budgetLimit]
SpendingForecast computeForecast({
  required double balance,
  required double? budgetLimit,
  required double spentSoFar,
  required int daysElapsed,
  required int daysInPeriod,
  required String? topCategory,
  required double topCategoryAmount,
}) {
  final safeDaysElapsed = daysElapsed < 1 ? 1 : daysElapsed;
  final dailyAvg = spentSoFar / safeDaysElapsed;
  final forecastSpend = dailyAvg * daysInPeriod;
  final daysRemaining = (daysInPeriod - daysElapsed).clamp(0, daysInPeriod);
  final projectedBalance = balance - dailyAvg * daysRemaining;
  final willBustBudget = budgetLimit != null && forecastSpend > budgetLimit;

  return SpendingForecast(
    projectedBalance: projectedBalance,
    forecastSpend: forecastSpend,
    willBustBudget: willBustBudget,
    topCategory: topCategory,
    topCategoryAmount: topCategoryAmount,
    daysRemaining: daysRemaining,
    dailyAvg: dailyAvg,
    budgetLimit: budgetLimit,
  );
}
