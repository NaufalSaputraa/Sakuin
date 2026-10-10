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

  /// Estimated number of days current balance will last at current burn rate.
  final int runwayDays;

  /// Projected date when liquid balance will be depleted, or null if indefinite.
  final DateTime? depletionDate;

  /// True if current balance can sustain spending until the end of the period.
  final bool survivesUntilMonthEnd;

  /// Recommended daily spending pace to ensure balance lasts until period end.
  final double suggestedDailyPace;

  /// Financial Health Score (0 - 100).
  final int healthScore;

  /// Financial Health Grade ('A', 'B', 'C', or 'D').
  final String healthGrade;

  const SpendingForecast({
    required this.projectedBalance,
    required this.forecastSpend,
    required this.willBustBudget,
    this.topCategory,
    required this.topCategoryAmount,
    required this.daysRemaining,
    required this.dailyAvg,
    this.budgetLimit,
    required this.runwayDays,
    this.depletionDate,
    required this.survivesUntilMonthEnd,
    required this.suggestedDailyPace,
    required this.healthScore,
    required this.healthGrade,
  });
}

/// Computes a [SpendingForecast] from raw inputs.
///
/// [budgetLimit] is `null` when there is no active budget — in that case
/// [willBustBudget] is always `false` (we still project the balance).
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
  final daysRemaining = (daysInPeriod - safeDaysElapsed).clamp(0, daysInPeriod);
  final projectedBalance = balance - dailyAvg * daysRemaining;
  final willBustBudget = budgetLimit != null && forecastSpend > budgetLimit;

  // Predictive Runway Calculation
  final int runwayDays = dailyAvg > 0
      ? (balance / dailyAvg).floor().clamp(0, 999)
      : (balance > 0 ? 999 : 0);
  final DateTime? depletionDate =
      runwayDays < 999 ? DateTime.now().add(Duration(days: runwayDays)) : null;
  final bool survivesUntilMonthEnd = runwayDays >= daysRemaining;
  final double suggestedDailyPace = daysRemaining > 0
      ? (balance / daysRemaining).clamp(0.0, double.infinity)
      : balance;

  // Financial Health Score Calculation (0..100)
  // Pillar 1: Budget Adherence (max 40 pts)
  int budgetPts = 40;
  if (budgetLimit != null && budgetLimit > 0) {
    final expectedSpentAtThisPoint = budgetLimit * (safeDaysElapsed / daysInPeriod);
    if (spentSoFar > expectedSpentAtThisPoint) {
      final overRatio = (spentSoFar - expectedSpentAtThisPoint) / budgetLimit;
      budgetPts = (40 - (overRatio * 50)).round().clamp(0, 40);
    }
  }

  // Pillar 2: Runway Resilience (max 35 pts)
  int runwayPts;
  if (runwayDays >= 60) {
    runwayPts = 35;
  } else if (runwayDays >= 30) {
    runwayPts = 30;
  } else if (survivesUntilMonthEnd) {
    runwayPts = 25;
  } else if (daysRemaining > 0) {
    runwayPts = ((runwayDays / daysRemaining) * 20).round().clamp(0, 20);
  } else {
    runwayPts = 10;
  }

  // Pillar 3: Balance Liquidity (max 25 pts)
  int balancePts = 25;
  if (balance <= 0) {
    balancePts = 0;
  } else if (projectedBalance < 0) {
    balancePts = 10;
  }

  final int healthScore = (budgetPts + runwayPts + balancePts).clamp(0, 100);
  final String healthGrade;
  if (healthScore >= 85) {
    healthGrade = 'A';
  } else if (healthScore >= 70) {
    healthGrade = 'B';
  } else if (healthScore >= 50) {
    healthGrade = 'C';
  } else {
    healthGrade = 'D';
  }

  return SpendingForecast(
    projectedBalance: projectedBalance,
    forecastSpend: forecastSpend,
    willBustBudget: willBustBudget,
    topCategory: topCategory,
    topCategoryAmount: topCategoryAmount,
    daysRemaining: daysRemaining,
    dailyAvg: dailyAvg,
    budgetLimit: budgetLimit,
    runwayDays: runwayDays,
    depletionDate: depletionDate,
    survivesUntilMonthEnd: survivesUntilMonthEnd,
    suggestedDailyPace: suggestedDailyPace,
    healthScore: healthScore,
    healthGrade: healthGrade,
  );
}
