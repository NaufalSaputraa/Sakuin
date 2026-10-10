import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/core/utils/billing_cycle_helper.dart';

void main() {
  group('BillingCycleHelper', () {
    test('getDaysInMonth handles regular months and leap years correctly', () {
      // Regular year 2026
      expect(BillingCycleHelper.getDaysInMonth(2026, 1), 31);
      expect(BillingCycleHelper.getDaysInMonth(2026, 2), 28);
      expect(BillingCycleHelper.getDaysInMonth(2026, 3), 31);
      expect(BillingCycleHelper.getDaysInMonth(2026, 4), 30);

      // Leap year 2024
      expect(BillingCycleHelper.getDaysInMonth(2024, 2), 29);
      // Leap year 2000
      expect(BillingCycleHelper.getDaysInMonth(2000, 2), 29);
      // Non-leap century 1900
      expect(BillingCycleHelper.getDaysInMonth(1900, 2), 28);
    });

    test('addMonthsWithClamping clamps January 31st to February 28th (non-leap)', () {
      final jan31 = DateTime(2026, 1, 31, 10, 0);
      final feb = BillingCycleHelper.addMonthsWithClamping(jan31, 1);
      expect(feb.year, 2026);
      expect(feb.month, 2);
      expect(feb.day, 28);
    });

    test('addMonthsWithClamping clamps January 31st to February 29th (leap year)', () {
      final jan31 = DateTime(2024, 1, 31, 14, 30);
      final feb = BillingCycleHelper.addMonthsWithClamping(jan31, 1);
      expect(feb.year, 2024);
      expect(feb.month, 2);
      expect(feb.day, 29);
    });

    test('addMonthsWithClamping restores original billing day on 31-day months', () {
      final feb28 = DateTime(2026, 2, 28);
      // Even if baseDate is Feb 28, passing billingDay: 31 restores March 31
      final march = BillingCycleHelper.addMonthsWithClamping(feb28, 1, billingDay: 31);
      expect(march.year, 2026);
      expect(march.month, 3);
      expect(march.day, 31);

      // April clamps to 30
      final april = BillingCycleHelper.addMonthsWithClamping(march, 1, billingDay: 31);
      expect(april.year, 2026);
      expect(april.month, 4);
      expect(april.day, 30);
    });

    test('calculateNextBillingDate returns immediate next month cycle by default', () {
      final jan31 = DateTime(2026, 1, 31);
      final next = BillingCycleHelper.calculateNextBillingDate(jan31);
      expect(next.year, 2026);
      expect(next.month, 2);
      expect(next.day, 28);
    });

    test('calculateNextBillingDate with rollToFuture returns future date when lastSeen was months ago', () {
      final lastSeen = DateTime(2026, 1, 15);
      final refDate = DateTime(2026, 4, 10);

      final next = BillingCycleHelper.calculateNextBillingDate(
        lastSeen,
        rollToFuture: true,
        referenceDate: refDate,
      );

      // Should advance from Jan 15 -> Feb 15 -> Mar 15 -> Apr 15
      expect(next.year, 2026);
      expect(next.month, 4);
      expect(next.day, 15);
      expect(next.isAfter(refDate), isTrue);
    });

    test('calculateNextBillingDate retains 31st pinning across year boundary', () {
      final lastSeen = DateTime(2025, 12, 31);

      final next = BillingCycleHelper.calculateNextBillingDate(lastSeen);

      // January has 31 days
      expect(next.year, 2026);
      expect(next.month, 1);
      expect(next.day, 31);
    });
  });
}
