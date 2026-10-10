import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/utils/currency_formatter.dart';
import '../../features/subscriptions/domain/subscription_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String billChannelId = 'channel_bill_reminders';
  static const String billChannelName = 'Pengingat Tagihan';
  static const String billChannelDesc = 'Notifikasi pengingat sebelum tagihan langganan jatuh tempo';

  static const String dailyReviewChannelId = 'channel_daily_review';
  static const String dailyReviewChannelName = 'Review Keuangan Harian';
  static const String dailyReviewChannelDesc = 'Pengingat malam untuk mencatat pengeluaran harian';

  static const int dailyReviewNotificationId = 99999;

  Future<void> init({void Function(NotificationResponse)? onNotificationTap}) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
      );

      // Request notification permissions on Android 13+
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Schedules H-3 and H-1 reminders for active subscriptions
  Future<void> scheduleSubscriptionReminders(List<SubscriptionModel> subscriptions) async {
    if (!_isInitialized) await init();

    for (final sub in subscriptions) {
      if (!sub.isActive) continue;

      final nextCharge = sub.nextChargeEstimate;
      final amountFormatted = RupiahFormatter.format(sub.amount);

      // H-3 Reminder at 09:00 AM
      final h3Date = nextCharge.subtract(const Duration(days: 3));
      final h3Scheduled = DateTime(h3Date.year, h3Date.month, h3Date.day, 9, 0);
      if (h3Scheduled.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: sub.id * 10 + 3,
          title: 'Pengingat Tagihan: ${sub.merchant}',
          body: 'Tagihan $amountFormatted akan jatuh tempo dalam 3 hari.',
          scheduledDate: h3Scheduled,
          channelId: billChannelId,
          channelName: billChannelName,
          channelDesc: billChannelDesc,
        );
      }

      // H-1 Reminder at 09:00 AM
      final h1Date = nextCharge.subtract(const Duration(days: 1));
      final h1Scheduled = DateTime(h1Date.year, h1Date.month, h1Date.day, 9, 0);
      if (h1Scheduled.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: sub.id * 10 + 1,
          title: 'Tagihan Jatuh Tempo Besok: ${sub.merchant}',
          body: 'Pastikan saldo dompet mencukupi untuk pembayaran $amountFormatted.',
          scheduledDate: h1Scheduled,
          channelId: billChannelId,
          channelName: billChannelName,
          channelDesc: billChannelDesc,
        );
      }
    }
  }

  /// Schedules daily review check-in reminder (defaults to 20:00 / 8 PM)
  Future<void> scheduleDailyReview({int hour = 20, int minute = 0}) async {
    if (!_isInitialized) await init();

    try {
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final tzScheduled = tz.TZDateTime.from(scheduled, tz.local);

      const androidDetails = AndroidNotificationDetails(
        dailyReviewChannelId,
        dailyReviewChannelName,
        channelDescription: dailyReviewChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const darwinDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.zonedSchedule(
        id: dailyReviewNotificationId,
        title: 'Catat Keuangan Hari Ini',
        body: 'Ada pengeluaran atau pemasukan yang belum tercatat hari ini?',
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleDailyReview error: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) async {
    try {
      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('_scheduleNotification error: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('cancelNotification error: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('cancelAll error: $e');
    }
  }
}
