import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/thousands_separator_formatter.dart';
import '../../domain/goal_model.dart';
import '../../providers/goal_providers.dart';

class GoalFormSheet extends ConsumerStatefulWidget {
  final GoalModel? goal;

  const GoalFormSheet({super.key, this.goal});

  static Future<void> show(BuildContext context, {GoalModel? goal}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalFormSheet(goal: goal),
    );
  }

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _currentAmountController;
  DateTime? _selectedDate;
  late String _selectedIcon;

  static const List<String> _availableIcons = [
    '🎯', '💻', '📱', '🚗', '🏠', '🏖️', '🎓', '💍', '🛡️', '🚲', '🎸', '✈️'
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _targetAmountController = TextEditingController(
      text: g != null ? RupiahFormatter.formatWithoutSymbol(g.targetAmount) : '',
    );
    _currentAmountController = TextEditingController(
      text: g != null ? RupiahFormatter.formatWithoutSymbol(g.currentAmount) : '',
    );
    _selectedDate = g?.targetDate;
    _selectedIcon = g?.icon ?? '🎯';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now.add(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final targetRaw = _targetAmountController.text.replaceAll('.', '').trim();
    final targetAmount = double.tryParse(targetRaw) ?? 0.0;
    if (targetAmount <= 0) return;

    final currentRaw = _currentAmountController.text.replaceAll('.', '').trim();
    final currentAmount = double.tryParse(currentRaw) ?? 0.0;

    final isEdit = widget.goal != null;
    final model = GoalModel(
      id: widget.goal?.id ?? 0,
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: _selectedDate,
      icon: _selectedIcon,
      isCompleted: currentAmount >= targetAmount,
      createdAt: widget.goal?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEdit) {
      await ref.read(goalNotifierProvider.notifier).updateGoal(model);
    } else {
      await ref.read(goalNotifierProvider.notifier).createGoal(model);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('goals.saved_snack'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEdit = widget.goal != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'goals.edit_goal'.tr() : 'goals.add_goal'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('common.delete'.tr()),
                            content: Text('goals.delete_confirm'.tr()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text('common.cancel'.tr()),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: Text('common.delete'.tr()),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          final deletedMsg = 'goals.deleted_snack'.tr();
                          await ref.read(goalNotifierProvider.notifier).deleteGoal(widget.goal!.id);
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(content: Text(deletedMsg)),
                          );
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Icon Picker Row
              Text('goals.icon'.tr(), style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableIcons.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final ic = _availableIcons[index];
                    final isSelected = ic == _selectedIcon;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = ic),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: colorScheme.primary, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(ic, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'goals.goal_name'.tr(),
                  hintText: 'Misal: Laptop Baru, Dana Darurat',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Target Amount Field
              TextFormField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  labelText: 'goals.target_amount'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  final parsed = double.tryParse((val ?? '').replaceAll('.', ''));
                  if (parsed == null || parsed <= 0) return 'Nominal target harus > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Current Amount Field
              TextFormField(
                controller: _currentAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  labelText: 'goals.current_amount'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Target Date Picker Tile
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_rounded, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd MMMM yyyy').format(_selectedDate!)
                              : 'goals.no_target_date'.tr(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (_selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _selectedDate = null),
                        )
                      else
                        const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'common.update'.tr() : 'common.save'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
