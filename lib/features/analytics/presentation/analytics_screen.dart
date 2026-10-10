import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../home/providers/spending_forecast_provider.dart';
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

const _fallbackPalette = [
  Color(0xFF6B5CE7), // Primary Purple
  Color(0xFF00CEC9), // Teal
  Color(0xFFFF7675), // Coral Red
  Color(0xFFFFA502), // Amber
  Color(0xFF2ED573), // Emerald Green
  Color(0xFF1E90FF), // Dodger Blue
  Color(0xFFFF4757), // Crimson
  Color(0xFF9B59B6), // Amethyst
  Color(0xFFFD79A8), // Pink
  Color(0xFF70A1FF), // Soft Blue
];

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
    final transactionsAsync = ref.watch(allTransactionsProvider);

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
            final int daysCount;
            switch (_selectedFilter) {
              case TimeFilter.thisMonth:
                daysCount = now.day;
                break;
              case TimeFilter.lastMonth:
                daysCount = DateTime(now.year, now.month, 0).day;
                break;
              case TimeFilter.thisYear:
                daysCount = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
                break;
              case TimeFilter.allTime:
                if (expenses.isNotEmpty) {
                  final earliest = expenses
                      .map((t) => t.transactionDate)
                      .reduce((a, b) => a.isBefore(b) ? a : b);
                  daysCount = now.difference(earliest).inDays + 1;
                } else {
                  daysCount = 1;
                }
                break;
            }
            final dailyAvg = daysCount > 0 ? totalSpent / daysCount : 0.0;

            // Group by category with distinct fallback color palette
            final Map<String, _CategoryStats> categoryMap = {};
            for (final tx in expenses) {
              final catName = tx.categoryName ?? 'Other';
              final icon = tx.categoryIcon ?? '📦';
              final Color color;
              if (tx.categoryColor != null && tx.categoryColor!.isNotEmpty) {
                color = tx.categoryColor!.toColor();
              } else {
                color = _fallbackPalette[categoryMap.length % _fallbackPalette.length];
              }

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
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                          '${'analytics.daily_avg'.tr()}: ${RupiahFormatter.format(dailyAvg)}${'analytics.per_day'.tr()}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Predictive Runway & Health Card
                  ref.watch(spendingForecastProvider).when(
                    data: (forecast) => Container(
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.insights_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'trend.healthScore'.tr(),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'trend.healthGrade'.tr(namedArgs: {'grade': forecast.healthGrade}),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'trend.runway'.tr(),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      forecast.runwayDays >= 999
                                          ? '99+ Hari'
                                          : '${forecast.runwayDays} Hari',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: forecast.survivesUntilMonthEnd
                                            ? Colors.green
                                            : Colors.amber[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Indeks Kesehatan',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${forecast.healthScore} / 100',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (forecast.healthScore / 100).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: theme.colorScheme.outlineVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                forecast.healthScore >= 70
                                    ? Colors.green
                                    : (forecast.healthScore >= 50 ? Colors.amber : theme.colorScheme.error),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            forecast.survivesUntilMonthEnd
                                ? 'trend.runwayMonthEndSafe'.tr(namedArgs: {'days': '${forecast.runwayDays}'})
                                : 'trend.runwayMonthEndDanger'.tr(namedArgs: {'days': '${forecast.runwayDays}'}),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Category Breakdown Chart (Pie / Donut)
                  Text(
                    'analytics.top_categories'.tr(),
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),

                  if (categoryList.isEmpty || totalSpent <= 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          'analytics.empty_transactions'.tr(),
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
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
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
                                    sectionsSpace: categoryList.length > 1 ? 2 : 0,
                                    centerSpaceRadius: 52,
                                    sections: categoryList.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final cat = entry.value;
                                      final isTouched = idx == _touchedPieIndex;
                                      final percentage = totalSpent > 0 ? (cat.amount / totalSpent) * 100 : 0.0;
                                      final showTitle = percentage >= 8.0;

                                      return PieChartSectionData(
                                        color: cat.color,
                                        value: cat.amount,
                                        title: showTitle ? '${percentage.toInt()}%' : '',
                                        radius: isTouched ? 36 : 30,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                // Centered Donut Content
                                IgnorePointer(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_touchedPieIndex >= 0 && _touchedPieIndex < categoryList.length) ...[
                                        Text(
                                          categoryList[_touchedPieIndex].icon,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          categoryList[_touchedPieIndex].name,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          RupiahFormatter.compact(categoryList[_touchedPieIndex].amount),
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: categoryList[_touchedPieIndex].color,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Total',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          RupiahFormatter.compact(totalSpent),
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Category Percentage Bars List
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categoryList.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                                      backgroundColor: theme.colorScheme.outlineVariant,
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
          loading: () => const ShimmerLoadingSection(section: ShimmerSection.analyticsChart),
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
