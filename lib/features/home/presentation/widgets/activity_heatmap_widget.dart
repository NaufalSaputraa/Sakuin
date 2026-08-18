import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../transactions/providers/transaction_providers.dart';

class ActivityHeatmapWidget extends ConsumerWidget {
  const ActivityHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    final transactions = transactionsAsync.asData?.value ?? [];

    // Map daily expenses for the last 14 weeks (98 days)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 97)); // 14 weeks * 7 days - 1

    final Map<DateTime, double> dailySpending = {};
    for (final tx in transactions) {
      if (tx.isExpense) {
        final d = DateTime(tx.transactionDate.year, tx.transactionDate.month, tx.transactionDate.day);
        dailySpending[d] = (dailySpending[d] ?? 0.0) + tx.amount;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'home.activity'.tr(),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '14 Minggu Terakhir',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Heatmap Grid: 7 rows (Days of week) x 14 columns (Weeks)
          SizedBox(
            height: 105,
            child: Row(
              children: [
                // Day Labels
                const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('S', style: TextStyle(fontSize: 10)),
                    Text('S', style: TextStyle(fontSize: 10)),
                    Text('R', style: TextStyle(fontSize: 10)),
                    Text('K', style: TextStyle(fontSize: 10)),
                    Text('J', style: TextStyle(fontSize: 10)),
                    Text('S', style: TextStyle(fontSize: 10)),
                    Text('M', style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 8),

                // Heatmap Matrix
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, colIndex) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (rowIndex) {
                          final dayOffset = (colIndex * 7) + rowIndex;
                          final cellDate = startDate.add(Duration(days: dayOffset));
                          final amount = dailySpending[cellDate] ?? 0.0;

                          return _HeatmapCell(
                            amount: amount,
                            isDark: isDark,
                            primaryColor: theme.colorScheme.primary,
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final double amount;
  final bool isDark;
  final Color primaryColor;

  const _HeatmapCell({
    required this.amount,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    Color cellColor;

    if (amount <= 0) {
      cellColor = isDark ? const Color(0xFF232338) : const Color(0xFFF0E5DA);
    } else if (amount < 50000) {
      cellColor = primaryColor.withValues(alpha: 0.3);
    } else if (amount < 150000) {
      cellColor = primaryColor.withValues(alpha: 0.6);
    } else {
      cellColor = primaryColor;
    }

    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}
