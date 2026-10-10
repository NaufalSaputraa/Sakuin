import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/goals/providers/goal_providers.dart';
import '../../../../features/goals/presentation/widgets/goal_card.dart';
import '../../../../features/goals/presentation/widgets/goal_form_sheet.dart';
import '../../../../features/goals/presentation/widgets/add_funds_dialog.dart';

class GoalsSection extends ConsumerWidget {
  const GoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goalsAsync = ref.watch(watchGoalsProvider);

    return goalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (goals) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'goals.title'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/goals'),
                  child: Text(
                    goals.isEmpty ? 'goals.add_goal'.tr() : 'home.view_all'.tr(),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (goals.isEmpty)
              _buildEmptyBanner(context, theme, colorScheme)
            else
              Column(
                children: goals.take(3).map((goal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoalCard(
                      goal: goal,
                      onTap: () => GoalFormSheet.show(context, goal: goal),
                      onAddFunds: () async {
                        final val = await AddFundsDialog.show(
                          context,
                          goal: goal,
                          actionType: FundActionType.add,
                        );
                        if (val != null) {
                          await ref.read(goalNotifierProvider.notifier).addFunds(
                                goalId: goal.id,
                                amount: val,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('goals.funds_added'.tr()),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      onWithdraw: () async {
                        final val = await AddFundsDialog.show(
                          context,
                          goal: goal,
                          actionType: FundActionType.withdraw,
                        );
                        if (val != null) {
                          await ref.read(goalNotifierProvider.notifier).withdrawFunds(
                                goalId: goal.id,
                                amount: val,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('goals.funds_withdrawn'.tr()),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text('✨', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'goals.empty_title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'goals.empty_desc'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => GoalFormSheet.show(context),
            tooltip: 'goals.add_goal'.tr(),
          ),
        ],
      ),
    );
  }
}
