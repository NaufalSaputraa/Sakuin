import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/extensions.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/providers/transaction_providers.dart';

enum TimeFilter {
  thisMonth,
  lastMonth,
  thisYear,
  allTime;

  String get labelKey {
    switch (this) {
      case TimeFilter.thisMonth:
        return 'analytics.this_month';
      case TimeFilter.lastMonth:
        return 'analytics.last_month';
      case TimeFilter.thisYear:
        return 'analytics.this_year';
      case TimeFilter.allTime:
        return 'analytics.all_time';
    }
  }
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  TimeFilter _selectedFilter = TimeFilter.thisMonth;
  int _touchedPieIndex = -1;

  List<TransactionModel> _filterTransactions(List<TransactionModel> all) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case TimeFilter.thisMonth:
        return all.where((tx) =>
            tx.transactionDate.year == now.year &&
            tx.transactionDate.month == now.month).toList();
      case TimeFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return all.where((tx) =>
            tx.transactionDate.year == lastMonth.year &&
            tx.transactionDate.month == lastMonth.month).toList();
      case TimeFilter.thisYear:
        return all.where((tx) => tx.transactionDate.year == now.year).toList();
      case TimeFilter.allTime:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('analytics.title'.tr()),
      ),
      body: SafeArea(
        child: transactionsAsync.when(
          data: (allTransactions) {
            final filtered = _filterTransactions(allTransactions);
            final expenses = filtered.where((tx) => tx.isExpense).toList();

            final totalSpent = expenses.fold(0.0, (sum, tx) => sum + tx.amount);
            final txnCount = expenses.length;

            final now = DateTime.now();
            final daysCount = _selectedFilter == TimeFilter.thisMonth ? now.day : 30;
            final dailyAvg = daysCount > 0 ? totalSpent / daysCount : 0.0;

            // Group by category
            final Map<String, _CategoryStats> categoryMap = {};
            for (final tx in expenses) {
              final catName = tx.categoryName ?? 'Other';
              final icon = tx.categoryIcon ?? '📦';
              final color = tx.categoryColor?.toColor() ?? theme.colorScheme.primary;

              final current = categoryMap[catName];
              if (current == null) {
                categoryMap[catName] = _CategoryStats(
                  name: catName,
                  icon: icon,
                  color: color,
                  amount: tx.amount,
                );
              } else {
                categoryMap[catName] = current.copyWith(
                  amount: current.amount + tx.amount,
                );
              }
            }

            final categoryList = categoryMap.values.toList()
              ..sort((a, b) => b.amount.compareTo(a.amount));

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips Row
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: TimeFilter.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = TimeFilter.values[index];
                        final isSelected = _selectedFilter == filter;

                        return ChoiceChip(
                          label: Text(filter.labelKey.tr()),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilter = filter);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                              'analytics.total_spent'.tr(),
                              style: theme.textTheme.bodySmall,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$txnCount TXNS',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          RupiahFormatter.format(totalSpent),
                          style: theme.textTheme.displayMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${'analytics.daily_avg'.tr()}: ${RupiahFormatter.format(dailyAvg)}/hari',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Breakdown Chart (Pie / Donut)
                  Text(
                    'analytics.top_categories'.tr(),
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),

                  if (categoryList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada data transaksi',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, response) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          response == null ||
                                          response.touchedSection == null) {
                                        _touchedPieIndex = -1;
                                        return;
                                      }
                                      _touchedPieIndex = response.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 3,
                                centerSpaceRadius: 44,
                                sections: categoryList.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final cat = entry.value;
                                  final isTouched = idx == _touchedPieIndex;
                                  final percentage = (cat.amount / totalSpent) * 100;

                                  return PieChartSectionData(
                                    color: cat.color,
                                    value: cat.amount,
                                    title: '${percentage.toInt()}%',
                                    radius: isTouched ? 38 : 32,
                                    titleStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Category Percentage Bars List
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categoryList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final cat = categoryList[index];
                              final percentage = (cat.amount / totalSpent).clamp(0.0, 1.0);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(cat.icon, style: const TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(cat.name, style: theme.textTheme.titleSmall),
                                        ],
                                      ),
                                      Text(
                                        RupiahFormatter.format(cat.amount),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      minHeight: 6,
                                      backgroundColor: isDark
                                          ? const Color(0xFF232338)
                                          : const Color(0xFFF0E5DA),
                                      valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _CategoryStats {
  final String name;
  final String icon;
  final Color color;
  final double amount;

  const _CategoryStats({
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
  });

  _CategoryStats copyWith({
    String? name,
    String? icon,
    Color? color,
    double? amount,
  }) {
    return _CategoryStats(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      amount: amount ?? this.amount,
    );
  }
}
