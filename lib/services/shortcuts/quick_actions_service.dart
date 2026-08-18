import 'package:quick_actions/quick_actions.dart';

enum QuickActionType {
  quickEntry('action_quick_entry'),
  scanReceipt('action_scan_receipt'),
  aiChat('action_ai_chat');

  final String typeId;
  const QuickActionType(this.typeId);

  static QuickActionType? fromTypeId(String id) {
    return QuickActionType.values.where((t) => t.typeId == id).firstOrNull;
  }
}

class QuickActionsService {
  final QuickActions _quickActions = const QuickActions();

  void init(Function(QuickActionType action) onActionTriggered) {
    _quickActions.setShortcutItems([
      const ShortcutItem(
        type: 'action_quick_entry',
        localizedTitle: 'Catat Pengeluaran',
        icon: 'ic_launcher',
      ),
      const ShortcutItem(
        type: 'action_scan_receipt',
        localizedTitle: 'Scan Struk OCR',
        icon: 'ic_launcher',
      ),
      const ShortcutItem(
        type: 'action_ai_chat',
        localizedTitle: 'Tanya Asisten AI',
        icon: 'ic_launcher',
      ),
    ]);

    _quickActions.initialize((shortcutType) {
      final action = QuickActionType.fromTypeId(shortcutType);
      if (action != null) {
        onActionTriggered(action);
      }
    });
  }
}
