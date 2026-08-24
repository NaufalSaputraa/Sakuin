import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../../core/utils/currency_formatter.dart';

/// Represents a single day in the activity heatmap.
class HeatmapDay {
  final DateTime date;
  final double total;
  final int count;
  final int intensity; // 0=null, 1:<50rb, 2:<150rb, 3:<500rb, 4:>=500rb

  const HeatmapDay({
    required this.date,
    required this.total,
    required this.count,
    required this.intensity,
  });

  /// Returns true if this day has no transactions.
  bool get isEmpty => count == 0;

  /// Returns a formatted string for tooltip display.
  String get tooltipText {
    if (isEmpty) return 'No transactions';
    return '${RupiahFormatter.format(total)} • $count ${count == 1 ? 'transaction' : 'transactions'} • ${_formatDate(date)}';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

/// Pure function to aggregate transactions into a heatmap map.
/// Testable and independent of Flutter/Providers.
Map<DateTime, HeatmapDay> aggregateHeatmap(
  List<TransactionModel> transactions, {
  int weeks = 52,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startDate = today.subtract(Duration(days: weeks * 7 - 1));

  // Initialize map with all days in range (empty days)
  final Map<DateTime, HeatmapDay> heatmap = {};
  for (int i = 0; i < weeks * 7; i++) {
    final day = startDate.add(Duration(days: i));
    heatmap[day] = HeatmapDay(date: day, total: 0, count: 0, intensity: 0);
  }

  // Aggregate expenses by day
  final Map<DateTime, _DayAggregate> dailyAggregates = {};
  for (final tx in transactions) {
    if (!tx.isExpense) continue; // Only expenses for heatmap
    final day = DateTime(tx.transactionDate.year, tx.transactionDate.month, tx.transactionDate.day);
    if (day.isBefore(startDate) || day.isAfter(today)) continue;

    dailyAggregates.putIfAbsent(day, () => _DayAggregate());
    dailyAggregates[day]!.add(tx.amount);
  }

  // Convert aggregates to HeatmapDay with intensity buckets
  for (final entry in dailyAggregates.entries) {
    final total = entry.value.total;
    final count = entry.value.count;
    final intensity = _calculateIntensity(total);
    heatmap[entry.key] = HeatmapDay(
      date: entry.key,
      total: total,
      count: count,
      intensity: intensity,
    );
  }

  return heatmap;
}

/// Internal helper for aggregation.
class _DayAggregate {
  double total = 0;
  int count = 0;

  void add(double amount) {
    total += amount;
    count++;
  }
}

/// Calculates intensity bucket based on RupiahFormatter thresholds.
/// 0 = null/empty, 1 = <50rb, 2 = <150rb, 3 = <500rb, 4 = >=500rb
int _calculateIntensity(double amount) {
  if (amount <= 0) return 0;
  if (amount < 50000) return 1;      // < 50rb
  if (amount < 150000) return 2;     // < 150rb
  if (amount < 500000) return 3;     // < 500rb
  return 4;                          // >= 500rb
}

/// Provider that watches heatmap transactions and aggregates them.
///
/// Riverpod 3 removed `StreamProvider.stream`, so the source provider's
/// [AsyncValue] emissions are bridged into a plain [Stream] to keep the
/// previous behavior (no reload flicker between emissions).
final heatmapDataProvider = StreamProvider.autoDispose<Map<DateTime, HeatmapDay>>((ref) {
  final controller = StreamController<Map<DateTime, HeatmapDay>>();

  ref.listen(
    heatmapTransactionsProvider,
    (_, next) {
      next.when(
        data: (transactions) =>
            controller.add(aggregateHeatmap(transactions, weeks: 52)),
        error: controller.addError,
        loading: () {},
      );
    },
    fireImmediately: true,
  );

  ref.onDispose(controller.close);
  return controller.stream;
});