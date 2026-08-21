import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/heatmap_data_provider.dart';

class ActivityHeatmapWidget extends ConsumerWidget {
  const ActivityHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final heatmapAsync = ref.watch(heatmapDataProvider);

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
                'heatmap.title'.tr(),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                'heatmap.range52Weeks'.tr(),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Month labels row
          _MonthLabelsRow(heatmapAsync: heatmapAsync),
          const SizedBox(height: 8),

          // Heatmap Grid: 7 rows (Days of week) x 52 columns (Weeks)
          heatmapAsync.when(
            data: (heatmap) => _HeatmapGrid(
              heatmap: heatmap,
              primaryColor: theme.colorScheme.primary,
            ),
            loading: () => const _HeatmapSkeleton(),
            error: (e, _) => _HeatmapError(error: e),
          ),
          const SizedBox(height: 12),

          // Legend
          _HeatmapLegend(primaryColor: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

/// Row showing month labels (MMM) above the heatmap columns
class _MonthLabelsRow extends StatelessWidget {
  final AsyncValue<Map<DateTime, HeatmapDay>> heatmapAsync;

  const _MonthLabelsRow({required this.heatmapAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return heatmapAsync.when(
      data: (heatmap) {
        if (heatmap.isEmpty) return const SizedBox.shrink();

        final dates = heatmap.keys.toList()..sort();
        final startDate = dates.first;
        final endDate = dates.last;

        // Generate month boundaries
        final months = <_MonthLabel>[];
        DateTime current = DateTime(startDate.year, startDate.month, 1);
        while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
          final monthStart = current;
          final monthEnd = DateTime(current.year, current.month + 1, 0);
          final firstDayIndex = monthStart.difference(startDate).inDays;
          final lastDayIndex = monthEnd.difference(startDate).inDays.clamp(0, dates.length - 1);
          final columnStart = (firstDayIndex / 7).floor();
          final columnEnd = (lastDayIndex / 7).floor();
          final columnSpan = columnEnd - columnStart + 1;

          months.add(_MonthLabel(
            month: current.month,
            columnStart: columnStart,
            columnSpan: columnSpan,
          ));

          current = DateTime(current.year, current.month + 1, 1);
        }

        return SizedBox(
          height: 18,
          child: Stack(
            children: months.map((m) => _MonthLabelWidget(
              label: _monthAbbreviation(m.month),
              columnStart: m.columnStart,
              columnSpan: m.columnSpan,
              textStyle: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            )).toList(),
          ),
        );
      },
      loading: () => const SizedBox(height: 18),
      error: (_, __) => const SizedBox(height: 18),
    );
  }

  String _monthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _MonthLabel {
  final int month;
  final int columnStart;
  final int columnSpan;

  _MonthLabel({
    required this.month,
    required this.columnStart,
    required this.columnSpan,
  });
}

class _MonthLabelWidget extends StatelessWidget {
  final String label;
  final int columnStart;
  final int columnSpan;
  final TextStyle? textStyle;

  const _MonthLabelWidget({
    required this.label,
    required this.columnStart,
    required this.columnSpan,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    const cellWidth = 11.0;
    const cellSpacing = 4.0;
    const dayLabelWidth = 16.0;
    const dayLabelSpacing = 8.0;

    final left = dayLabelWidth + dayLabelSpacing + columnStart * (cellWidth + cellSpacing);
    final width = columnSpan * (cellWidth + cellSpacing) - cellSpacing;

    return Positioned(
      left: left,
      top: 0,
      width: width,
      child: Text(
        label,
        style: textStyle,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Main heatmap grid with 7 rows x 52 columns
class _HeatmapGrid extends StatelessWidget {
  final Map<DateTime, HeatmapDay> heatmap;
  final Color primaryColor;

  const _HeatmapGrid({
    required this.heatmap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (heatmap.isEmpty) {
      return const SizedBox(height: 105);
    }

    final dates = heatmap.keys.toList()..sort();

    return SizedBox(
      height: 105,
      child: Row(
        children: [
          // Day Labels (Sun-Sat)
          const Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayLabel('S'),
              _DayLabel('M'),
              _DayLabel('T'),
              _DayLabel('W'),
              _DayLabel('T'),
              _DayLabel('F'),
              _DayLabel('S'),
            ],
          ),
          const SizedBox(width: 8),

          // Heatmap Matrix - 52 weeks
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 52,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, colIndex) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (rowIndex) {
                    final dayOffset = (colIndex * 7) + rowIndex;
                    if (dayOffset >= dates.length) {
                      return const _EmptyCell();
                    }
                    final cellDate = dates[dayOffset];
                    final heatmapDay = heatmap[cellDate]!;

                    return _HeatmapCell(
                      heatmapDay: heatmapDay,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String label;

  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}

/// Individual heatmap cell with tooltip on tap
class _HeatmapCell extends ConsumerWidget {
  final HeatmapDay heatmapDay;
  final Color primaryColor;
  final bool isDark;

  const _HeatmapCell({
    required this.heatmapDay,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Color cellColor;
    if (heatmapDay.isEmpty) {
      cellColor = isDark ? const Color(0xFF232338) : const Color(0xFFF0E5DA);
    } else {
      // Intensity 1-4 maps to alpha 0.25, 0.5, 0.75, 1.0
      final alpha = heatmapDay.intensity / 4.0;
      cellColor = primaryColor.withValues(alpha: alpha.clamp(0.25, 1.0));
    }

    return Tooltip(
      message: heatmapDay.tooltipText,
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onInverseSurface,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      verticalOffset: -32,
      preferBelow: false,
      child: Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}

/// Skeleton loader for heatmap
class _HeatmapSkeleton extends StatelessWidget {
  const _HeatmapSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF232338) : const Color(0xFFF0E5DA);

    return SizedBox(
      height: 105,
      child: Row(
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayLabel('S'),
              _DayLabel('M'),
              _DayLabel('T'),
              _DayLabel('W'),
              _DayLabel('T'),
              _DayLabel('F'),
              _DayLabel('S'),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 52,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, colIndex) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (rowIndex) {
                    return Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state for heatmap
class _HeatmapError extends StatelessWidget {
  final Object error;

  const _HeatmapError({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 105,
      child: Center(
        child: Text(
          'Failed to load heatmap',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

/// Legend showing Less/More with color gradient
class _HeatmapLegend extends StatelessWidget {
  final Color primaryColor;

  const _HeatmapLegend({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'heatmap.less'.tr(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Row(
          children: List.generate(4, (i) {
            final alpha = (i + 1) / 4.0;
            return Container(
              width: 11,
              height: 11,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(2.5),
              ),
            );
          }),
        ),
        Text(
          'heatmap.more'.tr(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}