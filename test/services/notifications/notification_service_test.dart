import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/features/subscriptions/domain/subscription_model.dart';
import 'package:sakuin_app/services/notifications/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService();
    });

    test('service can be instantiated with default channels and ids', () {
      expect(NotificationService.billChannelId, 'channel_bill_reminders');
      expect(NotificationService.dailyReviewChannelId, 'channel_daily_review');
      expect(NotificationService.dailyReviewNotificationId, 99999);
    });

    test('scheduleSubscriptionReminders handles empty and inactive subscriptions without throwing', () async {
      final inactiveSub = SubscriptionModel(
        id: 1,
        merchant: 'Spotify',
        normalizedKey: 'spotify',
        amount: 55000,
        period: 'monthly',
        firstSeen: DateTime(2026, 1, 1),
        lastSeen: DateTime(2026, 2, 1),
        occurrenceCount: 2,
        confidence: 0.9,
        isActive: false,
        isConfirmed: true,
        createdAt: DateTime(2026, 1, 1),
      );

      // Should complete gracefully without error
      await expectLater(
        service.scheduleSubscriptionReminders([inactiveSub]),
        completes,
      );
    });
  });
}
