import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/providers/category_providers.dart';
import '../../smart_rules/domain/smart_rule_model.dart';
import '../../smart_rules/providers/smart_rule_providers.dart';
import '../../wallets/domain/wallet_model.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../domain/transaction_model.dart';
import '../providers/transaction_providers.dart';
import '../../../services/ml/text_parser_service.dart';

class QuickEntrySheet extends ConsumerStatefulWidget {
  final String? initialText;
  final bool startInNumpadMode;

  const QuickEntrySheet({
    super.key,
    this.initialText,
    this.startInNumpadMode = false,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialText,
    bool startInNumpadMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickEntrySheet(
        initialText: initialText,
        startInNumpadMode: startInNumpadMode,
      ),
    );
  }

  @override
  ConsumerState<QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends ConsumerState<QuickEntrySheet> {
  late TextEditingController _textController;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late bool _isNumpadMode;

  TransactionType _transactionType = TransactionType.expense;
  int? _selectedWalletId;
  int? _selectedCategoryId;
  double _parsedAmount = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _titleController = TextEditingController(text: 'Transaksi');
    _amountController = TextEditingController();
    _isNumpadMode = widget.startInNumpadMode;

    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerParse(widget.initialText!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _triggerParse(String text) {
    if (text.trim().isEmpty) return;

    final parser = ref.read(textParserServiceProvider);
    final List<WalletModel> wallets = ref.read(allWalletsProvider).asData?.value ?? <WalletModel>[];
    final List<CategoryModel> categories = ref.read(allCategoriesProvider).asData?.value ?? <CategoryModel>[];

    _parseAndUpdate(text, parser, wallets, categories);
  }

  Future<void> _parseAndUpdate(String text, TextParserService parser, List<WalletModel> wallets, List<CategoryModel> categories) async {
    final result = await parser.parseText(
      text: text,
      availableWallets: wallets,
      availableCategories: categories,
    );

    setState(() {
      _transactionType = result.transactionType;
      _titleController.text = result.title;

      if (result.amount != null && result.amount! > 0) {
        _parsedAmount = result.amount!;
        _amountController.text = _parsedAmount.toStringAsFixed(0);
      }

      // Match category
      if (result.categoryKey != null) {
        final match = categories.where((c) => c.key == result.categoryKey).firstOrNull;
        if (match != null) {
          _selectedCategoryId = match.id;
        }
      }

      // Match wallet
      if (result.walletProvider != null) {
        final match = wallets.where((w) {
          if (result.walletProvider == 'physical') return w.isPhysical;
          return w.provider == result.walletProvider;
        }).firstOrNull;

        if (match != null) {
          _selectedWalletId = match.id;
        }
      }
    });
  }

  Future<void> _submitTransaction() async {
    final amount = _isNumpadMode
        ? (double.tryParse(_amountController.text.replaceAll('.', '')) ?? _parsedAmount)
        : _parsedAmount;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal transaksi yang valid')),
      );
      return;
    }

    final List<WalletModel> wallets = ref.read(allWalletsProvider).asData?.value ?? <WalletModel>[];
    final walletId = _selectedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null);

    if (walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu')),
      );
      return;
    }

    // Apply smart rules evaluation for auto-suggestions
    final merchant = _textController.text.trim();
    final title = _titleController.text.trim().isEmpty ? 'Transaksi' : _titleController.text.trim();
    final evaluationAsync = ref.read(
      smartRuleEvaluationProvider(
        (merchant: merchant, title: title, amount: amount, categoryId: _selectedCategoryId),
      ).future,
    );
    final evaluation = await evaluationAsync;

    int? finalCategoryId = _selectedCategoryId;
    int? finalWalletId = walletId;

    if (evaluation.hasMatch && evaluation.action != null) {
      final action = evaluation.action!;
      if (action.type == RuleActionType.categorize) {
        final actionData = _parseActionValue(action.value);
        final categoryId = actionData['categoryId'] as int?;
        if (categoryId != null) {
          finalCategoryId = categoryId;
        }
      } else if (action.type == RuleActionType.wallet) {
        final actionData = _parseActionValue(action.value);
        final walletProvider = actionData['walletProvider'] as String?;
        if (walletProvider != null) {
          final match = wallets.where((w) {
            if (walletProvider == 'physical') return w.isPhysical;
            return w.provider == walletProvider;
          }).firstOrNull;
          if (match != null) {
            finalWalletId = match.id;
          }
        }
      }
    }

    setState(() => _isLoading = true);

    final repo = ref.read(transactionRepositoryProvider);
    final result = await repo.createTransaction(
      walletId: finalWalletId,
      categoryId: finalCategoryId,
      amount: amount,
      transactionType: _transactionType,
      title: title,
      sourceInput: _isNumpadMode ? 'manual' : 'text_parse',
      rawInput: _textController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      await HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi ${RupiahFormatter.format(amount)} berhasil dicatat'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${result.errorOrNull?.message}')),
        );
      }
    }
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
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final walletsAsync = ref.watch(allWalletsProvider);
    final categoriesAsync = ref.watch(
      _transactionType == TransactionType.income
          ? incomeCategoriesProvider
          : expenseCategoriesProvider,
    );

    final List<WalletModel> wallets = walletsAsync.asData?.value ?? <WalletModel>[];
    final List<CategoryModel> categories = categoriesAsync.asData?.value ?? <CategoryModel>[];

    if (_selectedWalletId == null && wallets.isNotEmpty) {
      _selectedWalletId = wallets.first.id;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + 16,
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
            const SizedBox(height: 12),

            // Mode Selector Bar (Smart Input or Numpad)
            Row(
              children: [
                Expanded(
                  child: _isNumpadMode
                      ? TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            hintText: '0',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _parsedAmount = double.tryParse(val) ?? 0.0;
                            });
                          },
                        )
                      : TextField(
                          controller: _textController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'input.placeholder'.tr(),
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          onChanged: _triggerParse,
                          onSubmitted: _triggerParse,
                        ),
                ),
                IconButton.filled(
                  onPressed: _submitTransaction,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Type Toggle (Expense / Income / Transfer)
            Row(
              children: [
                _TypePill(
                  label: 'input.type_expense'.tr(),
                  isSelected: _transactionType == TransactionType.expense,
                  color: const Color(0xFFE74C3C),
                  onTap: () => setState(() => _transactionType = TransactionType.expense),
                ),
                const SizedBox(width: 8),
                _TypePill(
                  label: 'input.type_income'.tr(),
                  isSelected: _transactionType == TransactionType.income,
                  color: const Color(0xFF2ECC71),
                  onTap: () => setState(() => _transactionType = TransactionType.income),
                ),
                const SizedBox(width: 8),
                _TypePill(
                  label: 'input.type_transfer'.tr(),
                  isSelected: _transactionType == TransactionType.transfer,
                  color: const Color(0xFF3B82C4),
                  onTap: () => setState(() => _transactionType = TransactionType.transfer),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Parsed / Configured Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232338) : const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'input.amount'.tr(),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        RupiahFormatter.format(_parsedAmount),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${'input.title'.tr()}: ',
                        style: theme.textTheme.bodySmall,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wallet Selector Pills (Horizontal Scroll)
            Text(
              'input.wallet'.tr(),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final w = wallets[index];
                  final isSelected = _selectedWalletId == w.id;
                  return ChoiceChip(
                    label: Text('${w.icon ?? '💳'} ${w.name}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedWalletId = w.id);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Category Suggestion Chips (Horizontal Grid/Scroll)
            Text(
              'input.category'.tr(),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final c = categories[index];
                  final isSelected = _selectedCategoryId == c.id;
                  final localeCode = context.locale.languageCode;

                  return ChoiceChip(
                    label: Text('${c.icon} ${c.localizedName(localeCode)}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? c.id : null;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            FilledButton(
              onPressed: _submitTransaction,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('input.confirm'.tr()),
            ),
            const SizedBox(height: 8),

            // Toggle Numpad / Text Mode
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isNumpadMode = !_isNumpadMode;
                  });
                },
                child: Text(
                  _isNumpadMode ? 'input.switch_text'.tr() : 'input.switch_numpad'.tr(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
