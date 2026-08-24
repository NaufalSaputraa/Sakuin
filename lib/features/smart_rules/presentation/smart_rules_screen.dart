import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../domain/smart_rule_model.dart';
import '../providers/smart_rule_providers.dart';
import 'widgets/rule_editor_sheet.dart';

class SmartRulesScreen extends ConsumerWidget {
  const SmartRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rulesAsync = ref.watch(smartRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('smartRules.title'.tr()),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showRuleEditor(context, ref),
            tooltip: 'smartRules.add_rule'.tr(),
          ),
        ],
      ),
      body: rulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return _buildEmptyState(context, theme, ref);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _buildRuleCard(context, theme, ref, rule);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('smartRules.error_loading'.tr()),
              const SizedBox(height: 8),
              Text(e.toString(), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'smartRules.empty_title'.tr(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'smartRules.empty_description'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showRuleEditor(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text('smartRules.create_first'.tr()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    SmartRuleModel rule,
  ) {
    final actionLabel = _getActionLabel(rule.action);
    final conditionsLabel = _getConditionsLabel(rule.conditions);

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
                        rule.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conditionsLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.isActive,
                  onChanged: (value) {
                    ref.read(smartRulesNotifierProvider.notifier).toggleRule(rule.id, value);
                  },
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return theme.colorScheme.primary;
                    }
                    return null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    actionLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Priority: ${rule.priority}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showRuleEditor(context, ref, rule: rule),
                  tooltip: 'smartRules.edit'.tr(),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context, ref, rule),
                  tooltip: 'smartRules.delete'.tr(),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getActionLabel(RuleAction action) {
    switch (action.type) {
      case RuleActionType.categorize:
        final data = _parseActionValue(action.value);
        final categoryId = data['categoryId'] as int?;
        return 'smartRules.action_categorize'.tr(args: [categoryId?.toString() ?? '?']);
      case RuleActionType.wallet:
        final data = _parseActionValue(action.value);
        final walletProvider = data['walletProvider'] as String?;
        return 'smartRules.action_wallet'.tr(args: [walletProvider ?? '?']);
      case RuleActionType.tag:
        return 'smartRules.action_tag'.tr();
    }
  }

  String _getConditionsLabel(List<RuleCondition> conditions) {
    return conditions.map((c) {
      final fieldLabel = _getFieldLabel(c.field);
      final opLabel = _getOperatorLabel(c.operator);
      return '$fieldLabel $opLabel "${c.value}"';
    }).join(' AND ');
  }

  String _getFieldLabel(RuleField field) {
    switch (field) {
      case RuleField.merchant:
        return 'smartRules.field_merchant'.tr();
      case RuleField.title:
        return 'smartRules.field_title'.tr();
      case RuleField.amount:
        return 'smartRules.field_amount'.tr();
      case RuleField.categoryId:
        return 'smartRules.field_category'.tr();
    }
  }

  String _getOperatorLabel(RuleOperator op) {
    switch (op) {
      case RuleOperator.contains:
        return 'smartRules.op_contains'.tr();
      case RuleOperator.equals:
        return 'smartRules.op_equals'.tr();
      case RuleOperator.gt:
        return 'smartRules.op_gt'.tr();
      case RuleOperator.lt:
        return 'smartRules.op_lt'.tr();
      case RuleOperator.gte:
        return 'smartRules.op_gte'.tr();
      case RuleOperator.lte:
        return 'smartRules.op_lte'.tr();
    }
  }

  Map<String, dynamic> _parseActionValue(String value) {
    try {
      return Map<String, dynamic>.from(jsonDecode(value));
    } catch (_) {
      return {};
    }
  }

  void _showRuleEditor(BuildContext context, WidgetRef ref, {SmartRuleModel? rule}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RuleEditorSheet(rule: rule),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SmartRuleModel rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('smartRules.delete_confirm_title'.tr()),
        content: Text('smartRules.delete_confirm_message'.tr(args: [rule.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              ref.read(smartRulesNotifierProvider.notifier).deleteRule(rule.id);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}