import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../budget/providers/budget_providers.dart';
import '../../../transactions/providers/transaction_providers.dart';

class BudgetProgressWidget extends ConsumerWidget {
  const BudgetProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final budgetAsync = ref.watch(primaryBudgetProvider);
    final expenseAsync = ref.watch(currentMonthExpenseProvider);

    // Show shimmer while loading
    if (budgetAsync is AsyncLoading || expenseAsync is AsyncLoading) {
      return const ShimmerLoadingSection(section: ShimmerSection.budgetProgress);
    }

    final budget = budgetAsync.asData?.value;
    final spent = expenseAsync.asData?.value ?? 0.0;
    final limit = budget?.amount ?? 3000000.0; // Default preview limit if no budget set
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > limit;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Circular Progress Ring
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: isDark
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget
                        ? (isDark ? SakuinColors.darkExpense : SakuinColors.lightExpense)
                        : theme.colorScheme.primary,
                  ),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Budget Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      budget?.name ?? 'home.budget'.tr(),
                      style: theme.textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isOverBudget
                                ? (isDark ? SakuinColors.darkExpense : SakuinColors.lightExpense)
                                : (isDark ? SakuinColors.darkIncome : SakuinColors.lightIncome))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOverBudget ? 'home.over_budget'.tr() : 'home.on_track'.tr(),
                        style: TextStyle(
                          color: isOverBudget
                              ? (isDark ? SakuinColors.darkExpense : SakuinColors.lightExpense)
                              : (isDark ? SakuinColors.darkIncome : SakuinColors.lightIncome),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: NumberFlow(
                        value: spent,
                        format: const NumberFlowFormat.currency(
                          currencyCode: 'IDR',
                          symbol: 'Rp ',
                        ),
                        locale: 'id_ID',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        spinTiming: const TimingConfig(
                          duration: Duration(milliseconds: 400),
                          curve: NumberFlowCurve(),
                        ),
                      ),
                    ),
                    Text(
                      ' / ${RupiahFormatter.format(limit)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$daysRemaining ${'home.days_remaining'.tr()}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
