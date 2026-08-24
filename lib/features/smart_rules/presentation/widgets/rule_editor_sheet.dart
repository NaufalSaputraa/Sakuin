import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../features/categories/domain/category_model.dart';
import '../../../../features/wallets/domain/wallet_model.dart';
import '../../../../features/categories/providers/category_providers.dart';
import '../../../../features/wallets/providers/wallet_providers.dart';
import '../../domain/smart_rule_model.dart';
import '../../providers/smart_rule_providers.dart';

class RuleEditorSheet extends ConsumerStatefulWidget {
  final SmartRuleModel? rule;

  const RuleEditorSheet({super.key, this.rule});

  @override
  ConsumerState<RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends ConsumerState<RuleEditorSheet> {
  late TextEditingController _nameController;
  late List<RuleCondition> _conditions;
  RuleActionType _selectedActionType = RuleActionType.categorize;
  int? _selectedCategoryId;
  String? _selectedWalletProvider;
  int _priority = 999;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule?.name ?? '');
    _conditions = widget.rule?.conditions ?? [
      const RuleCondition(
        field: RuleField.merchant,
        operator: RuleOperator.contains,
        value: '',
      ),
    ];

    if (widget.rule != null) {
      _selectedActionType = widget.rule!.action.type;
      _priority = widget.rule!.priority;
      final actionData = _parseActionValue(widget.rule!.action.value);
      if (_selectedActionType == RuleActionType.categorize) {
        _selectedCategoryId = actionData['categoryId'] as int?;
      } else if (_selectedActionType == RuleActionType.wallet) {
        _selectedWalletProvider = actionData['walletProvider'] as String?;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseActionValue(String value) {
    try {
      return Map<String, dynamic>.from(jsonDecode(value));
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final walletsAsync = ref.watch(allWalletsProvider);

    final List<CategoryModel> categories = categoriesAsync.asData?.value ?? <CategoryModel>[];
    final List<WalletModel> wallets = walletsAsync.asData?.value ?? <WalletModel>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.rule == null ? 'smartRules.add_rule'.tr() : 'smartRules.edit_rule'.tr(),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Rule Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'smartRules.rule_name'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.rule_rounded),
              ),
            ),
            const SizedBox(height: 20),

            // Conditions Section
            Text('smartRules.conditions'.tr(), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._conditions.asMap().entries.map((entry) {
              final index = entry.key;
              final condition = entry.value;
              return _buildConditionCard(context, theme, index, condition, categories);
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addCondition,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('smartRules.add_condition'.tr()),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Action Section
            Text('smartRules.action'.tr(), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildActionSelector(context, theme, categories, wallets),
            const SizedBox(height: 20),

            // Priority
            Text('smartRules.priority'.tr(), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Slider(
              value: _priority.toDouble(),
              min: 0,
              max: 999,
              divisions: 999,
              label: _priority.toString(),
              onChanged: (value) => setState(() => _priority = value.round()),
            ),
            Text(
              'smartRules.priority_hint'.tr(args: [_priority.toString()]),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _saveRule,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                    )
                  : Text(widget.rule == null ? 'common.save'.tr() : 'common.update'.tr()),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionCard(
    BuildContext context,
    ThemeData theme,
    int index,
    RuleCondition condition,
    List<CategoryModel> categories,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<RuleField>(
                    initialValue: condition.field,
                    decoration: InputDecoration(
                      labelText: 'smartRules.field'.tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: RuleField.values.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text(_getFieldLabel(f)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _conditions[index] = condition.copyWith(field: value);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<RuleOperator>(
                    initialValue: condition.operator,
                    decoration: InputDecoration(
                      labelText: 'smartRules.operator'.tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: RuleOperator.values.map((o) {
                      return DropdownMenuItem(
                        value: o,
                        child: Text(_getOperatorLabel(o)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _conditions[index] = condition.copyWith(operator: value);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: condition.value),
              decoration: InputDecoration(
                labelText: 'smartRules.value'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _conditions[index] = condition.copyWith(value: value);
                });
              },
            ),
            if (_conditions.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _removeCondition(index),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text('common.remove'.tr()),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSelector(
    BuildContext context,
    ThemeData theme,
    List<CategoryModel> categories,
    List<WalletModel> wallets,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RuleActionType>(
          initialValue: _selectedActionType,
          decoration: InputDecoration(
            labelText: 'smartRules.action_type'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: RuleActionType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(_getActionTypeLabel(t)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedActionType = value;
                _selectedCategoryId = null;
                _selectedWalletProvider = null;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        if (_selectedActionType == RuleActionType.categorize) ...[
          DropdownButtonFormField<int>(
            initialValue: _selectedCategoryId,
            decoration: InputDecoration(
              labelText: 'smartRules.select_category'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: categories.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Text('${c.icon} ${c.localizedName(context.locale.languageCode)}'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategoryId = value),
          ),
        ] else if (_selectedActionType == RuleActionType.wallet) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedWalletProvider,
            decoration: InputDecoration(
              labelText: 'smartRules.select_wallet'.tr(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              ...wallets.where((w) => w.isPhysical).map((w) {
                return DropdownMenuItem(
                  value: 'physical',
                  child: Text('${w.icon ?? '💵'} ${w.name} (${'wallets.physical'.tr()})'),
                );
              }),
              ...wallets.where((w) => w.provider != null).map((w) {
                return DropdownMenuItem(
                  value: w.provider!,
                  child: Text('${w.icon ?? '📱'} ${w.name}'),
                );
              }),
            ],
            onChanged: (value) => setState(() => _selectedWalletProvider = value),
          ),
        ],
      ],
    );
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

  String _getActionTypeLabel(RuleActionType type) {
    switch (type) {
      case RuleActionType.categorize:
        return 'smartRules.action_categorize_label'.tr();
      case RuleActionType.wallet:
        return 'smartRules.action_wallet_label'.tr();
      case RuleActionType.tag:
        return 'smartRules.action_tag_label'.tr();
    }
  }

  void _addCondition() {
    setState(() {
      _conditions.add(const RuleCondition(
        field: RuleField.merchant,
        operator: RuleOperator.contains,
        value: '',
      ));
    });
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }

  Future<void> _saveRule() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('smartRules.name_required'.tr())),
      );
      return;
    }

    if (_conditions.any((c) => c.value.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('smartRules.condition_value_required'.tr())),
      );
      return;
    }

    String actionValue;
    if (_selectedActionType == RuleActionType.categorize) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('smartRules.category_required'.tr())),
        );
        return;
      }
      actionValue = jsonEncode({'categoryId': _selectedCategoryId});
    } else if (_selectedActionType == RuleActionType.wallet) {
      if (_selectedWalletProvider == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('smartRules.wallet_required'.tr())),
        );
        return;
      }
      actionValue = jsonEncode({'walletProvider': _selectedWalletProvider});
    } else {
      actionValue = jsonEncode({});
    }

    final action = RuleAction(type: _selectedActionType, value: actionValue);
    final rule = SmartRuleModel(
      id: widget.rule?.id ?? 0,
      name: name,
      isActive: widget.rule?.isActive ?? true,
      conditions: _conditions,
      action: action,
      priority: _priority,
      createdAt: widget.rule?.createdAt ?? DateTime.now(),
    );

    setState(() => _isLoading = true);

    try {
      if (widget.rule == null) {
        await ref.read(smartRulesNotifierProvider.notifier).addRule(rule);
      } else {
        await ref.read(smartRulesNotifierProvider.notifier).updateRule(rule);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.rule == null
                ? 'smartRules.created_success'.tr()
                : 'smartRules.updated_success'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('smartRules.save_error'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}