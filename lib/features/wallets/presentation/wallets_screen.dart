import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../currency/providers/currency_providers.dart';
import '../domain/wallet_model.dart';
import '../providers/wallet_providers.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  void _showAdjustBalanceDialog(BuildContext context, WalletModel wallet) {
    final controller = TextEditingController(text: wallet.balance.toInt().toString());
    String selectedCurrency = wallet.currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sesuaikan Saldo ${wallet.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: CurrencyFormatter.symbol(selectedCurrency),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: selectedCurrency,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'IDR', child: Text('IDR (Rp)')),
                DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                DropdownMenuItem(value: 'SGD', child: Text('SGD (S\$)')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                DropdownMenuItem(value: 'JPY', child: Text('JPY (¥)')),
                DropdownMenuItem(value: 'MYR', child: Text('MYR (RM)')),
              ],
              onChanged: (val) {
                if (val != null) selectedCurrency = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final newBal = double.tryParse(controller.text.trim());
              if (newBal != null) {
                final repo = ref.read(walletRepositoryProvider);
                await repo.updateWallet(wallet.copyWith(balance: newBal, currency: selectedCurrency));
              }
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
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
      '#3498DB', '#9B59B6', '#1ABC9C', '#E67E22',
      '#E74C3C', '#2ECC71', '#00AED6', '#118EEA',
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
            String selectedCurrency = 'IDR';
            final ratesAsync = ref.watch(currencyRatesProvider);
            final currencyCodes = ratesAsync.when(
              data: (rates) => rates.map((r) => r.code).toList(),
              loading: () => <String>['IDR'],
              error: (_, __) => <String>['IDR'],
            );
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Tambah E-Wallet / Rekening Baru', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Dompet (Contoh: Bank BCA / LinkAja / Jago)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Saldo Awal (Rp)',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Mata Uang Dompet', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedCurrency,
                      isExpanded: true,
                      items: currencyCodes.map((code) {
                        return DropdownMenuItem(
                          value: code,
                          child: Text('$code (${CurrencyFormatter.symbol(code)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedCurrency = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Pilih Warna Badge', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: colorList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final hex = colorList[idx];
                          final isSelected = hex == selectedColor;
                          final color = Color(int.parse(hex.replaceAll('#', '0xFF')));
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedColor = hex),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: color,
                              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
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
                          final bal = double.tryParse(balanceController.text.trim()) ?? 0.0;
                          if (name.isEmpty) return;

                          final provider = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                          final repo = ref.read(walletRepositoryProvider);

                          await repo.createWallet(
                            name: name,
                            walletType: 'digital',
                            parentId: digitalRootId,
                            provider: provider,
                            initialBalance: bal,
                            icon: selectedIcon,
                            color: selectedColor,
                            currency: selectedCurrency,
                          );

                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Simpan Dompet'),
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Transfer Antar Dompet', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 16),

                  // From Wallet
                  Text('Dari Dompet Asal', style: theme.textTheme.titleSmall),
                  DropdownButton<int>(
                    value: sourceWallet.id,
                    isExpanded: true,
                    items: wallets.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.name} (${RupiahFormatter.format(w.balance)})'),
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
                  Text('Ke Dompet Tujuan', style: theme.textTheme.titleSmall),
                  DropdownButton<int>(
                    value: targetWallet.id,
                    isExpanded: true,
                    items: wallets.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.name} (${RupiahFormatter.format(w.balance)})'),
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
                    decoration: const InputDecoration(
                      labelText: 'Nominal Transfer (Rp)',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0 || sourceWallet.id == targetWallet.id) return;

                        final repo = ref.read(walletRepositoryProvider);
                        // Update balances
                        await repo.updateWallet(sourceWallet.copyWith(balance: sourceWallet.balance - amount));
                        await repo.updateWallet(targetWallet.copyWith(balance: targetWallet.balance + amount));

                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Kirim Transfer'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final physicalWalletAsync = ref.watch(physicalWalletProvider);
    final digitalRootAsync = ref.watch(digitalRootWalletProvider);
    final subWalletsAsync = ref.watch(digitalSubWalletsProvider);
    final allWalletsAsync = ref.watch(allWalletsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Dompet & Saldo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Transfer Antar Dompet',
            onPressed: () {
              final wallets = allWalletsAsync.asData?.value ?? [];
              _showTransferSheet(context, wallets);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Dompet Fisik Section
          Text('Dompet Fisik (Tunai)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          physicalWalletAsync.when(
            data: (wallet) {
              if (wallet == null) return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2ECC71),
                    child: Text('💵', style: TextStyle(fontSize: 18)),
                  ),
                  title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Uang tunai fisik / cash on hand'),
                  trailing: Text(
                    RupiahFormatter.format(wallet.balance),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onTap: () => _showAdjustBalanceDialog(context, wallet),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),

          // 2. Dompet Digital Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dompet Digital (E-Wallet & Bank)', style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: () {
                  final root = digitalRootAsync.asData?.value;
                  _showAddWalletSheet(context, root?.id);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          subWalletsAsync.when(
            data: (subWallets) {
              if (subWallets.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada e-wallet terdaftar'),
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
                        child: Text(wallet.icon ?? '📱', style: const TextStyle(fontSize: 18)),
                      ),
                      title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Provider: ${wallet.provider ?? "Custom"}', style: theme.textTheme.bodySmall),
                      trailing: Text(
                        RupiahFormatter.format(wallet.balance),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final wallets = allWalletsAsync.asData?.value ?? [];
          _showTransferSheet(context, wallets);
        },
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('Transfer Saldo'),
      ),
    );
  }
}
