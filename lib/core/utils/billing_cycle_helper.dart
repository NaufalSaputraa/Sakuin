/// Utility for calculating calendar-accurate billing cycles.
/// Handles varying month lengths (28, 29, 30, 31 days) and leap years
/// without drifting over time.
class BillingCycleHelper {
  const BillingCycleHelper._();

  /// Returns the total number of days in the specified [year] and [month].
  /// Correctly accounts for leap years in February (29 days vs 28 days).
  static int getDaysInMonth(int year, int month) {
    // Day 0 of next month is the last day of target month.
    return DateTime(year, month + 1, 0).day;
  }

  /// Adds [monthsToAdd] calendar months to [baseDate] while pinning to [billingDay].
  ///
  /// If the target month has fewer days than [billingDay], the date is clamped
  /// to the last day of that month (e.g. Jan 31 -> Feb 28 in non-leap, or Feb 29 in leap year).
  /// Subsequent months can still restore the original [billingDay] if passed.
  static DateTime addMonthsWithClamping(
    DateTime baseDate,
    int monthsToAdd, {
    int? billingDay,
  }) {
    final targetBillingDay = billingDay ?? baseDate.day;
    final totalMonths = (baseDate.year * 12 + (baseDate.month - 1)) + monthsToAdd;
    final targetYear = totalMonths ~/ 12;
    final targetMonth = (totalMonths % 12) + 1;
    final maxDaysInMonth = getDaysInMonth(targetYear, targetMonth);
    final clampedDay = targetBillingDay > maxDaysInMonth ? maxDaysInMonth : targetBillingDay;

    return DateTime(
      targetYear,
      targetMonth,
      clampedDay,
      baseDate.hour,
      baseDate.minute,
      baseDate.second,
      baseDate.millisecond,
      baseDate.microsecond,
    );
  }

  /// Calculates the next monthly billing date from [lastSeen].
  ///
  /// - Pins to [originalBillingDay] (e.g. 15th, 31st) and clamps to month end if needed.
  /// - If [rollToFuture] is true, advances month-by-month until the candidate date
  ///   is on or after [referenceDate] (defaults to DateTime.now()).
  static DateTime calculateNextBillingDate(
    DateTime lastSeen, {
    int? originalBillingDay,
    bool rollToFuture = false,
    DateTime? referenceDate,
  }) {
    final billingDay = originalBillingDay ?? lastSeen.day;
    DateTime candidate = addMonthsWithClamping(lastSeen, 1, billingDay: billingDay);

    if (rollToFuture) {
      final now = referenceDate ?? DateTime.now();
      while (candidate.isBefore(now)) {
        candidate = addMonthsWithClamping(candidate, 1, billingDay: billingDay);
      }
    }
    return candidate;
  }
}
