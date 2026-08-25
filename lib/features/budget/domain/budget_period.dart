import 'budget_model.dart';

/// Window of an active budget period, used for forecasting.
class PeriodBounds {
  final DateTime start;
  final DateTime end;
  final int daysInPeriod;
  final int daysElapsed;

  const PeriodBounds({
    required this.start,
    required this.end,
    required this.daysInPeriod,
    required this.daysElapsed,
  });
}

/// Computes the active period window for [budget].
///
/// When [budget] is `null` (no active budget) it falls back to the current
/// calendar month so forecasts remain meaningful. The window is aligned to
/// [BudgetModel.startDate] and respects [BudgetModel.period] (daily / weekly /
/// monthly / yearly) rather than always using the calendar month — this keeps
/// weekly/daily budgets accurate.
PeriodBounds computePeriodBounds(BudgetModel? budget) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (budget == null) {
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final daysInPeriod = end.difference(start).inDays;
    final daysElapsed = today.difference(start).inDays + 1;
    return PeriodBounds(
      start: start,
      end: end,
      daysInPeriod: daysInPeriod,
      daysElapsed: daysElapsed.clamp(0, daysInPeriod),
    );
  }

  final start = DateTime(budget.startDate.year, budget.startDate.month, budget.startDate.day);
  late final DateTime end;
  late final int daysInPeriod;

  switch (budget.period) {
    case 'daily':
      end = start.add(const Duration(days: 1));
      daysInPeriod = 1;
      break;
    case 'weekly':
      end = start.add(const Duration(days: 7));
      daysInPeriod = 7;
      break;
    case 'yearly':
      end = DateTime(start.year + 1, start.month, start.day);
      daysInPeriod = end.difference(start).inDays;
      break;
    case 'monthly':
    default:
      end = start.month == 12
          ? DateTime(start.year + 1, 1, start.day)
          : DateTime(start.year, start.month + 1, start.day);
      daysInPeriod = end.difference(start).inDays;
      break;
  }

  final rawElapsed = today.difference(start).inDays;
  final daysElapsed = (rawElapsed < 0 ? 0 : rawElapsed) + 1;
  return PeriodBounds(
    start: start,
    end: end,
    daysInPeriod: daysInPeriod,
    daysElapsed: daysElapsed.clamp(0, daysInPeriod),
  );
}
