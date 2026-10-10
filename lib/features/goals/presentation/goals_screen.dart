import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/error_state_card.dart';
import '../providers/goal_providers.dart';
import 'widgets/goal_card.dart';
import 'widgets/goal_form_sheet.dart';
import 'widgets/add_funds_dialog.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goalsAsync = ref.watch(watchGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('goals.title'.tr()),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoalFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('goals.add_goal'.tr()),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorStateCard(message: '$err'),
          ),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          final totalTarget = goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
          final totalCurrent = goals.fold<double>(0, (sum, g) => sum + g.currentAmount);
          final overallProgress = totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0.0;
          final overallPercent = (overallProgress * 100).round();

          return CustomScrollView(
            slivers: [
              // Summary Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.surfaceContainerHighest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'goals.subtitle'.tr(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$overallPercent%',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          RupiahFormatter.format(totalCurrent),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'dari total target ${RupiahFormatter.format(totalTarget)} (${goals.length} target)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: overallProgress,
                            minHeight: 8,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Goals List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final goal = goals[index];
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
                    },
                    childCount: goals.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🎯', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 20),
            Text(
              'goals.empty_title'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'goals.empty_desc'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => GoalFormSheet.show(context),
              icon: const Icon(Icons.add_rounded),
              label: Text('goals.add_goal'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
