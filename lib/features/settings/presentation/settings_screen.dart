import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../budget/domain/budget_model.dart';
import '../../budget/providers/budget_providers.dart';
import '../../chat/providers/chat_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _userName = 'Pengguna Sakuin';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.userNameKey);
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _userName = name);
    }
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Profil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama Panggilan',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(AppConstants.userNameKey, newName);
                setState(() => _userName = newName);
              }
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog() {
    final budget = ref.read(primaryBudgetProvider).asData?.value;
    final currentAmount = budget?.amount ?? 3000000.0;
    final controller = TextEditingController(text: currentAmount.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur Batas Anggaran Bulanan'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal Limit (Rp)',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                final repo = ref.read(budgetRepositoryProvider);
                if (budget != null) {
                  await repo.updateBudget(budget.copyWith(amount: val));
                } else {
                  await repo.createBudget(
                    name: 'Anggaran Bulanan',
                    budgetType: BudgetType.limit,
                    amount: val,
                  );
                }
              }
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetAsync = ref.watch(primaryBudgetProvider);
    final budgetAmount = budgetAsync.asData?.value?.amount ?? 3000000.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setelan & Preferensi'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Profile Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Data Tersimpan 100% Lokal di HP',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: _showEditNameDialog,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Financial Management Section
          Text('Pengaturan Finansial', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Kelola Dompet & Saldo'),
            subtitle: const Text('Dompet Fisik & E-Wallet Digital (GoPay, OVO, dll)'),
            trailing: const Icon(Icons.chevron_right_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => context.push('/wallets'),
          ),
          const SizedBox(height: 4),

          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Kelola Kategori Transaksi'),
            subtitle: const Text('Kategori Pengeluaran & Pemasukan'),
            trailing: const Icon(Icons.chevron_right_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => context.push('/categories'),
          ),
          const SizedBox(height: 4),

          ListTile(
            leading: const Icon(Icons.track_changes_outlined),
            title: const Text('Batas Anggaran Bulanan'),
            subtitle: Text('Limit: ${RupiahFormatter.format(budgetAmount)} / bulan'),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: _showEditBudgetDialog,
          ),
          const SizedBox(height: 24),

          // 3. AI & OCR Engine Section
          Text('Mesin AI & Machine Learning', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.auto_awesome_rounded),
            title: const Text('Model AI On-Device'),
            subtitle: const Text('Google Gemma 2B-IT (Edge Optimized)'),
            trailing: Chip(
              label: const Text('Aktif', style: TextStyle(fontSize: 11)),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          const SizedBox(height: 4),

          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('Engine Scan Struk OCR'),
            subtitle: const Text('Google ML Kit Text Recognition (Kamera & Galeri)'),
            trailing: Chip(
              label: const Text('Siap', style: TextStyle(fontSize: 11)),
              backgroundColor: theme.colorScheme.secondaryContainer,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          const SizedBox(height: 4),

          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Hapus Riwayat Chat AI'),
            subtitle: const Text('Bersihkan memori percakapan dengan asisten'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () async {
              final chatRepo = ref.read(chatRepositoryProvider);
              await chatRepo.clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Riwayat chat AI berhasil dibersihkan!')),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // 4. Language & System
          Text('Bahasa & Tampilan', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('Bahasa Aplikasi'),
            subtitle: Text(context.locale.languageCode == 'id' ? 'Bahasa Indonesia' : 'English'),
            trailing: const Icon(Icons.swap_horiz_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () {
              final cur = context.locale.languageCode;
              context.setLocale(cur == 'id' ? const Locale('en') : const Locale('id'));
            },
          ),
          const SizedBox(height: 24),

          // 5. About Sakuin
          Text('Tentang Sakuin', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Versi Sakuin'),
            subtitle: const Text('v1.0.0 • Local-First Architecture • PennywiseAI-Inspired'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
