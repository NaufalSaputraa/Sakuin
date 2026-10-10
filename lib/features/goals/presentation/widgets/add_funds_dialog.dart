import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/thousands_separator_formatter.dart';
import '../../domain/goal_model.dart';

enum FundActionType { add, withdraw }

class AddFundsDialog extends StatefulWidget {
  final GoalModel goal;
  final FundActionType actionType;

  const AddFundsDialog({
    super.key,
    required this.goal,
    this.actionType = FundActionType.add,
  });

  static Future<double?> show(
    BuildContext context, {
    required GoalModel goal,
    FundActionType actionType = FundActionType.add,
  }) {
    return showDialog<double>(
      context: context,
      builder: (context) => AddFundsDialog(
        goal: goal,
        actionType: actionType,
      ),
    );
  }

  @override
  State<AddFundsDialog> createState() => _AddFundsDialogState();
}

class _AddFundsDialogState extends State<AddFundsDialog> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    _amountController.text = RupiahFormatter.formatWithoutSymbol(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdd = widget.actionType == FundActionType.add;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Text(widget.goal.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAdd ? 'goals.add_funds'.tr() : 'goals.withdraw_funds'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.goal.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                labelText: isAdd
                    ? 'goals.amount_to_add'.tr()
                    : 'goals.amount_to_withdraw'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _QuickChip(label: '+50rb', onTap: () => _setAmount(50000)),
                _QuickChip(label: '+100rb', onTap: () => _setAmount(100000)),
                _QuickChip(label: '+500rb', onTap: () => _setAmount(500000)),
                _QuickChip(label: '+1jt', onTap: () => _setAmount(1000000)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(
          onPressed: () {
            final raw = _amountController.text.replaceAll('.', '').trim();
            final val = double.tryParse(raw);
            if (val != null && val > 0) {
              Navigator.of(context).pop(val);
            }
          },
          child: Text('common.save'.tr()),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
