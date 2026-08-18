import 'package:flutter_test/flutter_test.dart';
import 'package:sakuin_app/services/shortcuts/quick_actions_service.dart';

void main() {
  group('QuickActionType Enum Tests', () {
    test('resolves typeId accurately', () {
      expect(QuickActionType.fromTypeId('action_quick_entry'), QuickActionType.quickEntry);
      expect(QuickActionType.fromTypeId('action_scan_receipt'), QuickActionType.scanReceipt);
      expect(QuickActionType.fromTypeId('action_ai_chat'), QuickActionType.aiChat);
      expect(QuickActionType.fromTypeId('unknown_action'), isNull);
    });
  });
}
