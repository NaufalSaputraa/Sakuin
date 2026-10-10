import 'package:home_widget/home_widget.dart';
import '../../core/utils/currency_formatter.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.sakuin.app';
  static const String quickActionBarWidget = 'QuickActionBarWidgetProvider';
  static const String budgetGlanceWidget = 'BudgetGlanceWidgetProvider';

  static Future<void> updateWidgetData({
    required double totalBalance,
    required double remainingBudget,
    String? latestTransactionTitle,
    double? latestTransactionAmount,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        'total_balance',
        RupiahFormatter.format(totalBalance),
      );
      await HomeWidget.saveWidgetData<String>(
        'remaining_budget',
        RupiahFormatter.format(remainingBudget),
      );
      if (latestTransactionTitle != null && latestTransactionAmount != null) {
        await HomeWidget.saveWidgetData<String>(
          'latest_tx',
          '$latestTransactionTitle: -${RupiahFormatter.format(latestTransactionAmount)}',
        );
      }

      await HomeWidget.updateWidget(
        name: quickActionBarWidget,
        androidName: quickActionBarWidget,
      );
      await HomeWidget.updateWidget(
        name: budgetGlanceWidget,
        androidName: budgetGlanceWidget,
      );
    } catch (_) {
      // Graceful fallback on unsupported platforms
    }
  }

  /// Listens to widget clicks (both cold start and warm foreground transitions)
  /// and triggers [onActionTriggered] with the target deep link Uri.
  static Future<void> registerInteractivityCallback(
    void Function(Uri uri) onActionTriggered,
  ) async {
    try {
      // Check if launched directly from home widget tap on cold start
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null) {
        onActionTriggered(initialUri);
      }
      // Listen to future widget clicks while app is in foreground/background
      HomeWidget.widgetClicked.listen((uri) {
        if (uri != null) {
          onActionTriggered(uri);
        }
      });
    } catch (_) {
      // Graceful fallback on unsupported platforms
    }
  }
}
