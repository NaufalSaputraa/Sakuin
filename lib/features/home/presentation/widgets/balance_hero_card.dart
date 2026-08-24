import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../transactions/providers/transaction_providers.dart';
import '../../../wallets/providers/wallet_providers.dart';

class BalanceHeroCard extends ConsumerStatefulWidget {
  const BalanceHeroCard({super.key});

  @override
  ConsumerState<BalanceHeroCard> createState() => _BalanceHeroCardState();
}

class _BalanceHeroCardState extends ConsumerState<BalanceHeroCard> {
  bool _isBalanceHidden = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final incomeAsync = ref.watch(currentMonthIncomeProvider);
    final expenseAsync = ref.watch(currentMonthExpenseProvider);

    final totalBalance = totalBalanceAsync.asData?.value ?? 0.0;
    final income = incomeAsync.asData?.value ?? 0.0;
    final expense = expenseAsync.asData?.value ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
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
                'home.total_balance'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _isBalanceHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  setState(() => _isBalanceHidden = !_isBalanceHidden);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          _isBalanceHidden
              ? Text(
                  '••••••••',
                  style: theme.textTheme.displayLarge?.copyWith(
                    letterSpacing: -0.5,
                  ),
                )
              : NumberFlow(
                  value: totalBalance,
                  format: const NumberFlowFormat.currency(
                    currencyCode: 'IDR',
                    symbol: 'Rp ',
                  ),
                  locale: 'id_ID',
                  style: theme.textTheme.displayLarge?.copyWith(
                    letterSpacing: -0.5,
                  ),
                  spinTiming: const TimingConfig(
                    duration: Duration(milliseconds: 600),
                    curve: NumberFlowCurve(),
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetricPill(
                label: 'home.income'.tr(),
                amount: _isBalanceHidden ? '••••' : '+${RupiahFormatter.compact(income)}',
                color: theme.brightness == Brightness.dark
                    ? SakuinColors.darkIncome
                    : SakuinColors.lightIncome,
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(width: 10),
              _MetricPill(
                label: 'home.expense'.tr(),
                amount: _isBalanceHidden ? '••••' : '-${RupiahFormatter.compact(expense)}',
                color: theme.brightness == Brightness.dark
                    ? SakuinColors.darkExpense
                    : SakuinColors.lightExpense,
                icon: Icons.arrow_upward_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _MetricPill({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $amount',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
