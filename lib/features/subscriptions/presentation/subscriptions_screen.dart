import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/subscription_model.dart';
import '../providers/subscription_providers.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detectedAsync = ref.watch(detectedSubscriptionsProvider);
    final savedAsync = ref.watch(watchSubscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('subscription.list.title'.tr()),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(subscriptionsNotifierProvider.notifier).detectAndSave(),
            tooltip: 'Refresh detection',
          ),
        ],
      ),
      body: detectedAsync.when(
        data: (detected) {
          return savedAsync.when(
            data: (saved) {
              final savedKeys = saved.map((s) => s.normalizedKey).toSet();
              final newDetected = detected.where((d) => !savedKeys.contains(d.normalizedKey)).toList();
              final allSubscriptions = [...saved, ...newDetected.map((d) => SubscriptionModel(
                id: 0,
                merchant: d.merchant,
                normalizedKey: d.normalizedKey,
                amount: d.amount,
                period: d.period,
                categoryId: d.categoryId,
                firstSeen: d.firstSeen,
                lastSeen: d.lastSeen,
                occurrenceCount: d.occurrenceCount,
                confidence: d.confidence,
                isActive: true,
                isConfirmed: false,
                createdAt: DateTime.now(),
              ))];

              if (allSubscriptions.isEmpty) {
                return _buildEmptyState(context, theme);
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: allSubscriptions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sub = allSubscriptions[index];
                  final isDetected = sub.id == 0;
                  return _buildSubscriptionCard(context, theme, ref, sub, isDetected);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
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
            Icon(
              Icons.subscriptions_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'subscription.empty'.tr(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'subscription.empty_description'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    SubscriptionModel sub,
    bool isDetected,
  ) {
    final confidencePercent = (sub.confidence * 100).round();
    final nextChargeFormat = DateFormat('dd MMM yyyy', context.locale.languageCode);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.merchant,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'subscription.monthly'.tr(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(confidencePercent, theme).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${'subscription.confidence'.tr()}: $confidencePercent%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getConfidenceColor(confidencePercent, theme),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  RupiahFormatter.format(sub.amount),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  '${'subscription.nextCharge'.tr()}: ${nextChargeFormat.format(sub.nextChargeEstimate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                if (isDetected) ...[
                  TextButton.icon(
                    onPressed: () async {
                      final notifier = ref.read(subscriptionsNotifierProvider.notifier);
                      // Create a proper model and upsert
                      final model = SubscriptionModel(
                        id: 0,
                        merchant: sub.merchant,
                        normalizedKey: sub.normalizedKey,
                        amount: sub.amount,
                        period: sub.period,
                        categoryId: sub.categoryId,
                        firstSeen: sub.firstSeen,
                        lastSeen: sub.lastSeen,
                        occurrenceCount: sub.occurrenceCount,
                        confidence: sub.confidence,
                        isActive: true,
                        isConfirmed: true,
                        createdAt: DateTime.now(),
                      );
                      final repo = ref.read(subscriptionRepositoryProvider);
                      await repo.upsert(model);
                      await notifier.detectAndSave();
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('subscription.confirm'.tr()),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      // Just dismiss - don't save
                      ref.invalidate(detectedSubscriptionsProvider);
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text('subscription.ignore'.tr()),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ] else if (!sub.isConfirmed) ...[
                  TextButton.icon(
                    onPressed: () => ref.read(subscriptionsNotifierProvider.notifier).confirmSubscription(sub.id),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('subscription.confirm'.tr()),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showIgnoreDialog(context, ref, sub),
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: Text('subscription.ignore'.tr()),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ] else ...[
                  Chip(
                    label: Text(
                      sub.isActive ? 'Active' : 'Ignored',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: sub.isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: sub.isActive
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    side: BorderSide.none,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Color _getConfidenceColor(int percent, ThemeData theme) {
    if (percent >= 80) return Colors.green;
    if (percent >= 60) return Colors.orange;
    return theme.colorScheme.error;
  }

  void _showIgnoreDialog(BuildContext context, WidgetRef ref, SubscriptionModel sub) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('subscription.ignore'.tr()),
        content: Text('Ignore "${sub.merchant}"? This will hide it from the list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              ref.read(subscriptionsNotifierProvider.notifier).ignoreSubscription(sub.id);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            child: Text('subscription.ignore'.tr()),
          ),
        ],
      ),
    );
  }
}