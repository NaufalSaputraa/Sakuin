import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../domain/spending_forecast.dart';
import '../../providers/spending_forecast_provider.dart';

class AiSpendingRecommendationWidget extends ConsumerWidget {
  const AiSpendingRecommendationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = context.locale.languageCode;
    final forecastAsync = ref.watch(spendingForecastProvider);
    final adviceAsync = ref.watch(aiSpendingAdviceProvider(locale));

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
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'trend.title'.tr(),
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
                  'AI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          forecastAsync.when(
            data: (forecast) => _ForecastContent(
              forecast: forecast,
              adviceAsync: adviceAsync,
            ),
            loading: () => const _ForecastSkeleton(),
            error: (e, _) => _ForecastError(error: e),
          ),
        ],
      ),
    );
  }
}

class _ForecastContent extends StatelessWidget {
  final SpendingForecast forecast;
  final AsyncValue<String?> adviceAsync;

  const _ForecastContent({
    required this.forecast,
    required this.adviceAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final willBust = forecast.willBustBudget;
    final statusColor = willBust ? theme.colorScheme.error : Colors.green;

    final gemmaText = adviceAsync.when(
      data: (text) => text,
      loading: () => null,
      error: (_, stack) => null,
    );

    final String adviceText;
    if (gemmaText != null && gemmaText.isNotEmpty) {
      adviceText = gemmaText;
    } else if (forecast.topCategory == null) {
      adviceText = willBust ? 'trend.willBust'.tr() : 'trend.safe'.tr();
    } else {
      final saved = forecast.topCategoryAmount * 0.2;
      final newBalance = forecast.projectedBalance + saved;
      adviceText = 'trend.adviceTemplate'.tr(namedArgs: {
        'category': forecast.topCategory!,
        'amount': RupiahFormatter.format(forecast.topCategoryAmount),
        'saved': RupiahFormatter.format(newBalance),
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'trend.projectedBalance'.tr(),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          RupiahFormatter.format(forecast.projectedBalance),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: willBust ? theme.colorScheme.error : theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                willBust ? 'trend.willBust'.tr() : 'trend.safe'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            if (forecast.topCategory != null)
              Text(
                '${'trend.topCategory'.tr()}: ${forecast.topCategory}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        if (forecast.budgetLimit != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (forecast.forecastSpend / forecast.budgetLimit!)
                  .clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${RupiahFormatter.format(forecast.forecastSpend)} / ${RupiahFormatter.format(forecast.budgetLimit!)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            adviceText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ForecastSkeleton extends StatelessWidget {
  const _ForecastSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerSkeleton(width: 160, height: 14, borderRadius: 6),
        SizedBox(height: 12),
        ShimmerSkeleton(width: 200, height: 30, borderRadius: 8),
        SizedBox(height: 16),
        ShimmerSkeleton(width: double.infinity, height: 8, borderRadius: 6),
        SizedBox(height: 12),
        ShimmerSkeleton(width: double.infinity, height: 56, borderRadius: 14),
      ],
    );
  }
}

class _ForecastError extends StatelessWidget {
  final Object error;

  const _ForecastError({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Failed to load spending forecast',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}
