import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/quick_entry_sheet.dart';
import '../../../transactions/providers/transaction_providers.dart';

class RecentTransactionsSection extends ConsumerWidget {
  final VoidCallback onViewAllTap;

  const RecentTransactionsSection({
    super.key,
    required this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home.recent_transactions'.tr(),
              style: theme.textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: onViewAllTap,
              child: Text('home.view_all'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 40,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'home.empty_transactions'.tr(),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'home.empty_transactions_cta'.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length > 5 ? 5 : transactions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 64,
                  color: theme.colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return _TransactionTile(tx: tx)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 40))
                      .slideY(begin: 0.05, end: 0);
                },
              ),
            );
          },
          loading: () => const ShimmerLoadingSection(section: ShimmerSection.recentTransactions),
          error: (err, _) => Center(
            child: Text('Error loading transactions: $err'),
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final TransactionModel tx;

  const _TransactionTile({required this.tx});

  Future<bool> _confirmDelete(BuildContext context, TransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('common.delete'.tr()),
        content: Text(
          'smartRules.delete_confirm_message'.tr(namedArgs: {'name': tx.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isIncome = tx.isIncome;
    final isTransfer = tx.isTransfer;

    final isDark = theme.brightness == Brightness.dark;
    final amountColor = isIncome
        ? (isDark ? SakuinColors.darkIncome : SakuinColors.lightIncome)
        : (isTransfer
            ? (isDark ? SakuinColors.darkSecondary : SakuinColors.lightSecondary)
            : (isDark ? SakuinColors.darkExpense : SakuinColors.lightExpense));

    final prefix = isIncome ? '+' : (isTransfer ? '' : '-');

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) => _confirmDelete(context, tx),
      onDismissed: (_) {
        ref.read(transactionActionsProvider.notifier).deleteTransaction(tx.id);
      },
      child: ListTile(
        onTap: () => QuickEntrySheet.show(context, transaction: tx),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: (tx.categoryColor?.toColor() ?? theme.colorScheme.primary)
              .withValues(alpha: 0.15),
          child: Text(
            tx.categoryIcon ?? (isIncome ? '💰' : '🛒'),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          tx.title,
          style: theme.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${tx.walletName ?? 'Wallet'} • ${tx.transactionDate.toFormattedTime()}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          '$prefix${RupiahFormatter.format(tx.amount)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ),
    );
  }
}
