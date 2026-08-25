import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/result.dart';
import '../../../core/theme/color_schemes.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/providers/category_providers.dart';
import '../../currency/providers/currency_providers.dart';
import '../../smart_rules/domain/smart_rule_model.dart';
import '../../smart_rules/providers/smart_rule_providers.dart';
import '../../wallets/domain/wallet_model.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../../share/providers/share_import_provider.dart';
import '../domain/transaction_model.dart';
import '../providers/transaction_providers.dart';
import '../presentation/receipt_scan_sheet.dart';
import '../presentation/voice_input_sheet.dart';
import '../../../services/ml/text_parser_service.dart';
import '../../../services/ml/parsed_transaction.dart';

class QuickEntrySheet extends ConsumerStatefulWidget {
  final String? initialText;
  final bool startInNumpadMode;
  final TransactionModel? transaction;

  const QuickEntrySheet({
    super.key,
    this.initialText,
    this.startInNumpadMode = false,
    this.transaction,
  }) : assert(initialText == null || transaction == null,
            'Cannot open the sheet in both parse and edit mode at once');

  static Future<void> show(
    BuildContext context, {
    String? initialText,
    bool startInNumpadMode = false,
    TransactionModel? transaction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickEntrySheet(
        initialText: initialText,
        startInNumpadMode: startInNumpadMode,
        transaction: transaction,
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
  String? _parsedMerchant; // From parser/OCR/voice/share; feeds subscriptions & smart rules
  bool _isLoading = false;
  String _selectedCurrency = 'IDR';
  DateTime _transactionDate = DateTime.now();

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _titleController = TextEditingController(text: 'Transaksi');
    _amountController = TextEditingController();
    _isNumpadMode = widget.startInNumpadMode || _isEditMode;
    _selectedCurrency = ref.read(selectedCurrencyProvider);

    // Edit mode: pre-fill the form from the existing transaction.
    final existing = widget.transaction;
    if (existing != null) {
      _transactionType = existing.transactionType;
      _titleController.text = existing.title;
      _parsedAmount = existing.amount;
      _amountController.text = existing.amount.toStringAsFixed(0);
      _selectedWalletId = existing.walletId;
      _selectedCategoryId = existing.categoryId;
      _selectedCurrency = existing.currency;
      _parsedMerchant = existing.merchant;
      _transactionDate = existing.transactionDate;
    }

    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerParse(widget.initialText!);
      });
    }

    // Share Import: auto-fill from text shared into Sakuin from another app
    // (banking / e-wallet) when this sheet was opened by that share.
    final pendingShare = ref.read(shareImportProvider);
    if (pendingShare.hasPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applySharedImport(pendingShare);
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
    final result = await parser.parseText(text: text);

    setState(() {
      _transactionType = result.transactionType;
      _titleController.text = result.title;
      _parsedMerchant = (result.merchant?.trim().isNotEmpty ?? false)
          ? result.merchant!.trim()
          : result.title;

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

    final title = _titleController.text.trim().isEmpty ? 'Transaksi' : _titleController.text.trim();

    int? finalCategoryId = _selectedCategoryId;
    int? finalWalletId = walletId;

    if (!_isEditMode) {
      // Apply smart rules evaluation for auto-suggestions. In edit mode we skip
      // this so the user's explicit category/wallet choices are preserved.
      final merchant = _textController.text.trim();
      final evaluationAsync = ref.read(
        smartRuleEvaluationProvider(
          (merchant: merchant, title: title, amount: amount, categoryId: _selectedCategoryId),
        ).future,
      );
      final evaluation = await evaluationAsync;

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
      }

    setState(() => _isLoading = true);

    // Persist selected currency for next entry.
    ref.read(selectedCurrencyProvider.notifier).set(_selectedCurrency);

    final merchantForTx = (_parsedMerchant?.trim().isNotEmpty ?? false)
        ? _parsedMerchant!.trim()
        : title;

    final Result<int, AppError> result;
    if (_isEditMode) {
      result = await ref.read(transactionActionsProvider.notifier).updateTransaction(
            id: widget.transaction!.id,
            walletId: finalWalletId,
            categoryId: finalCategoryId,
            amount: amount,
            transactionType: _transactionType,
            title: title,
            merchant: merchantForTx,
            transferToWalletId: widget.transaction!.transferToWalletId,
            transactionDate: _transactionDate,
            currency: _selectedCurrency,
          );
    } else {
      final repo = ref.read(transactionRepositoryProvider);
      result = await repo.createTransaction(
        walletId: finalWalletId,
        categoryId: finalCategoryId,
        amount: amount,
        transactionType: _transactionType,
        title: title,
        merchant: merchantForTx,
        sourceInput: _isNumpadMode ? 'manual' : 'text_parse',
        rawInput: _textController.text.trim(),
        currency: _selectedCurrency,
      );
    }

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      await HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'input.transaction_saved'.tr()} ${CurrencyFormatter.format(amount, _selectedCurrency)}'),
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

  Future<void> _openOcr() async {
    final parsed = await ReceiptScanSheet.show(context);
    if (parsed != null && mounted) {
      _applyParsed(parsed);
    }
  }

  Future<void> _openVoice() async {
    final parsed = await VoiceInputSheet.show(context);
    if (parsed != null && mounted) {
      _applyParsed(parsed);
    }
  }

  void _applyParsed(ParsedTransaction parsed) {
    final categories =
        ref.read(allCategoriesProvider).asData?.value ?? <CategoryModel>[];
    final wallets =
        ref.read(allWalletsProvider).asData?.value ?? <WalletModel>[];

    setState(() {
      _transactionType = parsed.transactionType;
      _titleController.text = parsed.title;
      _parsedMerchant = (parsed.merchant?.trim().isNotEmpty ?? false)
          ? parsed.merchant!.trim()
          : parsed.title;

      if (parsed.amount != null && parsed.amount! > 0) {
        _parsedAmount = parsed.amount!;
        _amountController.text = _parsedAmount.toStringAsFixed(0);
      }

      if (parsed.categoryKey != null) {
        final match = categories.where((c) => c.key == parsed.categoryKey).firstOrNull;
        if (match != null) _selectedCategoryId = match.id;
      }

      if (parsed.walletProvider != null) {
        final match = wallets.where((w) {
          if (parsed.walletProvider == 'physical') return w.isPhysical;
          return w.provider == parsed.walletProvider;
        }).firstOrNull;
        if (match != null) _selectedWalletId = match.id;
      }
    });
  }

  /// Applies a transaction shared from another app (Share Import) into the
  /// form, then marks it consumed so it is not applied twice.
  void _applySharedImport(ShareImportState shareState) {
    final parsed = shareState.parsed;
    if (parsed == null) return;

    setState(() {
      _textController.text = shareState.sharedText ?? _textController.text;
    });
    _applyParsed(parsed);

    ref.read(shareImportProvider.notifier).consume();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Share Import: handle texts arriving while the sheet is already open.
    ref.listen<ShareImportState>(shareImportProvider, (prev, next) {
      if (next.hasPending && next.sharedText != prev?.sharedText) {
        _applySharedImport(next);
      }
    });

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
                            prefixText: CurrencyFormatter.symbol(_selectedCurrency),
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
                IconButton(
                  onPressed: _isLoading ? null : _openVoice,
                  icon: const Icon(Icons.mic_rounded),
                  tooltip: 'voice.tapToSpeak'.tr(),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _openOcr,
                  icon: const Icon(Icons.document_scanner_rounded),
                  tooltip: 'ocr.cameraTitle'.tr(),
                ),
                IconButton.filled(
                  onPressed: _submitTransaction,
                  icon: _isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Type Toggle (Expense / Income / Transfer)
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return RepaintBoundary(
                  child: Row(
                    children: [
                      _TypePill(
                        label: 'input.type_expense'.tr(),
                        isSelected: _transactionType == TransactionType.expense,
                        color: isDark ? SakuinColors.darkExpense : SakuinColors.lightExpense,
                        onTap: () => setState(() => _transactionType = TransactionType.expense),
                      ),
                      const SizedBox(width: 8),
                      _TypePill(
                        label: 'input.type_income'.tr(),
                        isSelected: _transactionType == TransactionType.income,
                        color: isDark ? SakuinColors.darkIncome : SakuinColors.lightIncome,
                        onTap: () => setState(() => _transactionType = TransactionType.income),
                      ),
                      const SizedBox(width: 8),
                      _TypePill(
                        label: 'input.type_transfer'.tr(),
                        isSelected: _transactionType == TransactionType.transfer,
                        color: isDark ? SakuinColors.darkSecondary : SakuinColors.lightSecondary,
                        onTap: () => setState(() => _transactionType = TransactionType.transfer),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Parsed / Configured Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
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
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(_parsedAmount, _selectedCurrency),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CurrencyPicker(
                            value: _selectedCurrency,
                            onChanged: (code) => setState(() => _selectedCurrency = code),
                          ),
                        ],
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
                separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                separatorBuilder: (_, _) => const SizedBox(width: 8),
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
              child: Text(_isEditMode ? 'common.update'.tr() : 'input.confirm'.tr()),
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CurrencyPicker extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencyPicker({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ratesAsync = ref.watch(currencyRatesProvider);

    final codes = ratesAsync.when(
      data: (rates) => rates.map((r) => r.code).toList(),
      loading: () => <String>['IDR'],
      error: (_, _) => <String>['IDR'],
    );

    if (!codes.contains(value)) codes.add(value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        isDense: true,
        items: codes.map((code) {
          return DropdownMenuItem(
            value: code,
            child: Text(code),
          );
        }).toList(),
        onChanged: (code) {
          if (code != null) onChanged(code);
        },
      ),
    );
  }
}
