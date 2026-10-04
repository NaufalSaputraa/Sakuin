import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/thousands_separator_formatter.dart';
import '../../../core/theme/color_schemes.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../domain/wallet_model.dart';
import '../providers/wallet_providers.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  void _showAdjustBalanceDialog(BuildContext context, WalletModel wallet) {
    final controller = TextEditingController(
      text: RupiahFormatter.formatWithoutSymbol(wallet.balance),
    );
    const String selectedCurrency = 'IDR';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('wallets.adjust_balance_title'.tr(namedArgs: {'name': wallet.name})),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              final cleaned = controller.text.trim().replaceAll('.', '').replaceAll(',', '.');
              final newBal = double.tryParse(cleaned);
              if (newBal != null) {
                final repo = ref.read(walletRepositoryProvider);
                await repo.updateWallet(
                  wallet.copyWith(balance: newBal, currency: selectedCurrency),
                );
                ref.invalidate(allWalletsProvider);
                ref.invalidate(totalBalanceProvider);
              }
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddWalletSheet(BuildContext context, int? digitalRootId) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    String selectedColor = '#3498DB';
    String selectedIcon = '📱';

    final List<String> colorList = [
      '#3498DB',
      '#9B59B6',
      '#1ABC9C',
      '#E67E22',
      '#E74C3C',
      '#2ECC71',
      '#00AED6',
      '#118EEA',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'wallets.add_new_title'.tr(),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'wallets.name_label'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: InputDecoration(
                        labelText: 'wallets.initial_balance_label'.tr(),
                        prefixText: 'Rp ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mata Uang Dompet',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    // Currency dropdown removed, locked to IDR
                    const SizedBox(height: 16),
                    Text(
                      'Pilih Warna Badge',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: colorList.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final hex = colorList[idx];
                          final isSelected = hex == selectedColor;
                          final color = Color(
                            int.parse(hex.replaceAll('#', '0xFF')),
                          );
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedColor = hex),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: color,
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: theme.colorScheme.onPrimary,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final bal =
                              double.tryParse(balanceController.text.trim()) ??
                              0.0;
                          if (name.isEmpty) return;

                          final provider = name.toLowerCase().replaceAll(
                            RegExp(r'\s+'),
                            '_',
                          );
                          final repo = ref.read(walletRepositoryProvider);

                          await repo.createWallet(
                            name: name,
                            walletType: 'digital',
                            parentId: digitalRootId,
                            provider: provider,
                            initialBalance: bal,
                            icon: selectedIcon,
                            color: selectedColor,
                            currency: 'IDR',
                          );

                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: Text('wallets.save_wallet'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTransferSheet(BuildContext context, List<WalletModel> wallets) {
    final theme = Theme.of(context);
    if (wallets.length < 2) return;

    WalletModel sourceWallet = wallets.first;
    WalletModel targetWallet = wallets[1];
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'wallets.transfer_title'.tr(),
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),

                  // From Wallet
                  Text('wallets.transfer_from'.tr(), style: theme.textTheme.titleSmall),
                  DropdownButton<int>(
                    value: sourceWallet.id,
                    isExpanded: true,
                    items: wallets.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text(
                          '${w.name} (${RupiahFormatter.format(w.balance)})',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setSheetState(() {
                        sourceWallet = wallets.firstWhere((w) => w.id == val);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // To Wallet
                  Text('wallets.transfer_to'.tr(), style: theme.textTheme.titleSmall),
                  DropdownButton<int>(
                    value: targetWallet.id,
                    isExpanded: true,
                    items: wallets.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text(
                          '${w.name} (${RupiahFormatter.format(w.balance)})',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setSheetState(() {
                        targetWallet = wallets.firstWhere((w) => w.id == val);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'wallets.transfer_amount'.tr(),
                      prefixText: 'Rp ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final cleaned = amountController.text.trim().replaceAll('.', '').replaceAll(',', '.');
                        final amount = double.tryParse(cleaned);
                        if (amount == null ||
                            amount <= 0 ||
                            sourceWallet.id == targetWallet.id) {
                          return;
                        }

                        final txRepo = ref.read(transactionRepositoryProvider);
                        await txRepo.createTransaction(
                          walletId: sourceWallet.id,
                          transferToWalletId: targetWallet.id,
                          amount: amount,
                          transactionType: TransactionType.transfer,
                          title: 'Transfer ${sourceWallet.name} -> ${targetWallet.name}',
                          sourceInput: 'manual',
                          currency: 'IDR',
                        );

                        ref.invalidate(allWalletsProvider);
                        ref.invalidate(totalBalanceProvider);
                        ref.invalidate(recentTransactionsProvider);
                        ref.invalidate(allTransactionsProvider);

                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text('wallets.send_transfer'.tr()),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WalletModel wallet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('wallets.delete_title'.tr()),
        content: Text(
          'wallets.delete_message'.tr(namedArgs: {'name': wallet.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _deleteWallet(context, wallet);
    }
  }

  Future<void> _deleteWallet(BuildContext context, WalletModel wallet) async {
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.deleteWallet(wallet.id);
    if (!context.mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(allWalletsProvider);
        ref.invalidate(digitalSubWalletsProvider);
        ref.invalidate(physicalWalletProvider);
        ref.invalidate(digitalRootWalletProvider);
        ref.invalidate(totalBalanceProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('wallets.deleted_snack'.tr(namedArgs: {'name': wallet.name}))),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final physicalWalletAsync = ref.watch(physicalWalletProvider);
    final digitalRootAsync = ref.watch(digitalRootWalletProvider);
    final subWalletsAsync = ref.watch(digitalSubWalletsProvider);
    final allWalletsAsync = ref.watch(allWalletsProvider);

    final sections = <Widget>[
      // 1. Dompet Fisik Section
      Text('wallets.physical_title'.tr(), style: theme.textTheme.titleMedium),
      const SizedBox(height: 10),
      physicalWalletAsync.when(
        data: (wallet) {
          if (wallet == null) return const SizedBox.shrink();
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.brightness == Brightness.dark
                    ? SakuinColors.darkIncome
                    : SakuinColors.lightIncome,
                child: const Text('💵', style: TextStyle(fontSize: 18)),
              ),
              title: Text(
                wallet.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('wallets.physical_desc'.tr()),
              trailing: Text(
                RupiahFormatter.format(wallet.balance),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onTap: () => _showAdjustBalanceDialog(context, wallet),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
      const SizedBox(height: 24),

      // 2. Dompet Digital Root Section - balance mirroring fisik
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'wallets.digital_root_title'.tr(),
            style: theme.textTheme.titleMedium,
          ),
          TextButton.icon(
            onPressed: () {
              final root = digitalRootAsync.asData?.value;
              _showAddWalletSheet(context, root?.id);
            },
            icon: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
            label: Text(
              'wallets.add_button'.tr(),
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),

      digitalRootAsync.when(
        data: (rootWallet) {
          if (rootWallet == null) return const SizedBox.shrink();
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.brightness == Brightness.dark
                    ? SakuinColors.darkIncome
                    : SakuinColors.lightIncome,
                child: const Text('📱', style: TextStyle(fontSize: 18)),
              ),
              title: Text(
                rootWallet.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('wallets.digital_root_desc'.tr()),
              trailing: Text(
                RupiahFormatter.format(rootWallet.balance),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onTap: () => _showAdjustBalanceDialog(context, rootWallet),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
      const SizedBox(height: 24),

      // 3. Sub-Wallets Section
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'wallets.sub_wallets_title'.tr(),
            style: theme.textTheme.titleMedium,
          ),
          TextButton.icon(
            onPressed: () {
              final root = digitalRootAsync.asData?.value;
              _showAddWalletSheet(context, root?.id);
            },
            icon: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
            label: Text(
              'wallets.add_button'.tr(),
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      subWalletsAsync.when(
        data: (subWallets) {
          if (subWallets.isEmpty) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('wallets.no_sub_wallets'.tr()),
              ),
            );
          }
          return Column(
            children: subWallets.map((wallet) {
              final color = wallet.color != null
                  ? Color(int.parse(wallet.color!.replaceAll('#', '0xFF')))
                  : theme.colorScheme.primary;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      wallet.icon ?? '📱',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(
                    wallet.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Provider: ${wallet.provider ?? "Custom"}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        RupiahFormatter.format(wallet.balance),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: theme.colorScheme.error,
                        tooltip: 'Hapus Dompet',
                        onPressed: () =>
                            _showDeleteConfirmDialog(context, wallet),
                      ),
                    ],
                  ),
                  onTap: () => _showAdjustBalanceDialog(context, wallet),
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('wallets.manage_title'.tr()),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.onSurface),
            tooltip: 'wallets.transfer_title'.tr(),
            onPressed: () {
              final wallets = allWalletsAsync.asData?.value ?? [];
              _showTransferSheet(context, wallets);
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length,
        itemBuilder: (context, index) => sections[index],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final wallets = allWalletsAsync.asData?.value ?? [];
          _showTransferSheet(context, wallets);
        },
        icon: Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.onPrimary),
        label: Text(
          'wallets.transfer_title'.tr(),
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
