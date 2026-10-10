import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ml/parsed_transaction.dart';
import '../ml/text_parser_service.dart';

class IncomingMutationNotification {
  final String packageName;
  final String title;
  final String text;
  final DateTime timestamp;
  final ParsedTransaction? parsedTransaction;

  const IncomingMutationNotification({
    required this.packageName,
    required this.title,
    required this.text,
    required this.timestamp,
    this.parsedTransaction,
  });

  bool get hasValidTransaction =>
      parsedTransaction != null && parsedTransaction!.hasAmount;
}

class MutationNotificationListenerService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.sakuin.app/notification_listener');
  static const EventChannel _eventChannel =
      EventChannel('com.sakuin.app/notification_stream');

  /// Checks if Notification Listener permission is granted in Android system settings
  Future<bool> isPermissionGranted() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result = await _methodChannel.invokeMethod<bool>('isPermissionGranted');
      return result ?? false;
    } catch (e) {
      debugPrint('[MutationListener] isPermissionGranted error: $e');
      return false;
    }
  }

  /// Opens Android System Settings page to allow user to grant Notification Listener access
  Future<void> openPermissionSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('openPermissionSettings');
    } catch (e) {
      debugPrint('[MutationListener] openPermissionSettings error: $e');
    }
  }

  /// Stream of raw incoming notifications parsed into structured types
  Stream<IncomingMutationNotification> watchIncomingNotifications({
    required TextParserService parserService,
  }) {
    if (kIsWeb || !Platform.isAndroid) return const Stream.empty();

    return _eventChannel.receiveBroadcastStream().asyncMap((event) async {
      final map = Map<String, dynamic>.from(event as Map);
      final pkg = map['packageName'] as String? ?? '';
      final title = map['title'] as String? ?? '';
      final text = map['text'] as String? ?? '';
      final timeMs = map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

      final combined = '$title $text'.trim();
      final parsed = await parserService.parseText(text: combined);

      return IncomingMutationNotification(
        packageName: pkg,
        title: title,
        text: text,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timeMs),
        parsedTransaction: parsed,
      );
    });
  }
}

final mutationNotificationServiceProvider =
    Provider<MutationNotificationListenerService>((ref) {
  return MutationNotificationListenerService();
});

class MutationDetectorState {
  final bool isPermissionGranted;
  final IncomingMutationNotification? pendingMutation;

  const MutationDetectorState({
    this.isPermissionGranted = false,
    this.pendingMutation,
  });

  MutationDetectorState copyWith({
    bool? isPermissionGranted,
    IncomingMutationNotification? pendingMutation,
    bool clearPending = false,
  }) {
    return MutationDetectorState(
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      pendingMutation:
          clearPending ? null : (pendingMutation ?? this.pendingMutation),
    );
  }
}

class MutationDetectorNotifier extends Notifier<MutationDetectorState> {
  StreamSubscription<IncomingMutationNotification>? _subscription;

  @override
  MutationDetectorState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    return const MutationDetectorState();
  }

  Future<void> init() async {
    final service = ref.read(mutationNotificationServiceProvider);
    final parser = ref.read(textParserServiceProvider);

    final granted = await service.isPermissionGranted();
    state = state.copyWith(isPermissionGranted: granted);

    if (granted && _subscription == null) {
      _subscription = service
          .watchIncomingNotifications(parserService: parser)
          .listen((notification) {
        if (notification.hasValidTransaction) {
          state = state.copyWith(pendingMutation: notification);
        }
      });
    }
  }

  Future<void> checkPermission() async {
    final service = ref.read(mutationNotificationServiceProvider);
    final granted = await service.isPermissionGranted();
    state = state.copyWith(isPermissionGranted: granted);
    if (granted && _subscription == null) {
      await init();
    }
  }

  void dismissPending() {
    state = state.copyWith(clearPending: true);
  }
}

final mutationDetectorProvider =
    NotifierProvider<MutationDetectorNotifier, MutationDetectorState>(() {
  return MutationDetectorNotifier();
});
