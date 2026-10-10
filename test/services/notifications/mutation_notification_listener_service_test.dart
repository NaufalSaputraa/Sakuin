import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/services/ml/parsed_transaction.dart';
import 'package:sakuin_app/services/notifications/mutation_notification_listener_service.dart';

void main() {
  group('MutationNotificationListenerService', () {
    test('IncomingMutationNotification hasValidTransaction checks', () {
      final notificationWithoutParsed = IncomingMutationNotification(
        packageName: 'com.bca',
        title: 'BCA mobile',
        text: 'Transfer masuk Rp 50.000',
        timestamp: DateTime(2026, 10, 10),
      );
      expect(notificationWithoutParsed.hasValidTransaction, isFalse);

      final notificationWithZeroAmount = IncomingMutationNotification(
        packageName: 'com.bca',
        title: 'BCA mobile',
        text: 'Login berhasil',
        timestamp: DateTime(2026, 10, 10),
        parsedTransaction: const ParsedTransaction(
          amount: 0,
          title: 'Login',
          rawInput: 'Login berhasil',
        ),
      );
      expect(notificationWithZeroAmount.hasValidTransaction, isFalse);

      final validNotification = IncomingMutationNotification(
        packageName: 'com.bca',
        title: 'BCA mobile',
        text: 'Transfer masuk Rp 150.000 dari BUDI',
        timestamp: DateTime(2026, 10, 10),
        parsedTransaction: const ParsedTransaction(
          amount: 150000,
          title: 'Transfer dari BUDI',
          rawInput: 'Transfer masuk Rp 150.000 dari BUDI',
        ),
      );
      expect(validNotification.hasValidTransaction, isTrue);
      expect(validNotification.parsedTransaction?.amount, 150000);
    });

    test('MutationDetectorState copyWith and clearPending', () {
      const initial = MutationDetectorState();
      expect(initial.isPermissionGranted, isFalse);
      expect(initial.pendingMutation, isNull);

      final notification = IncomingMutationNotification(
        packageName: 'id.dana',
        title: 'DANA',
        text: 'Kamu menerima Rp 25.000',
        timestamp: DateTime(2026, 10, 10),
      );

      final updated = initial.copyWith(
        isPermissionGranted: true,
        pendingMutation: notification,
      );
      expect(updated.isPermissionGranted, isTrue);
      expect(updated.pendingMutation, equals(notification));

      final cleared = updated.copyWith(clearPending: true);
      expect(cleared.isPermissionGranted, isTrue);
      expect(cleared.pendingMutation, isNull);
    });

    test('isPermissionGranted returns false safely in test environment', () async {
      final service = MutationNotificationListenerService();
      final granted = await service.isPermissionGranted();
      expect(granted, isFalse);
    });
  });
}
