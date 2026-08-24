import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../budget/domain/budget_model.dart';
import '../../budget/providers/budget_providers.dart';
import '../../chat/providers/chat_providers.dart';
import '../../currency/domain/currency_model.dart';
import '../../currency/providers/currency_providers.dart';
import 'ai_model_section.dart';
import '../providers/export_import_provider.dart';

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

          // 2b. Currency & Offline Rates Section
          Text('currency.section_title'.tr(), style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          const _CurrencyRatesSection(),
          const SizedBox(height: 24),

          // 3. AI & OCR Engine Section
          Text('Mesin AI & Machine Learning', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          const AiModelSection(),
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
          const SizedBox(height: 4),

          ListTile(
            leading: const Icon(Icons.auto_fix_high_rounded),
            title: const Text('Aturan Pintar (Smart Rules)'),
            subtitle: const Text('Otomatisasi kategori & dompet berdasarkan merchant'),
            trailing: const Icon(Icons.chevron_right_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => context.push('/smart-rules'),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.subscriptions_rounded),
            title: const Text('Langganan Berulang'),
            subtitle: const Text('Deteksi & kelola subscription bulanan otomatis'),
            trailing: const Icon(Icons.chevron_right_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => context.push('/subscriptions'),
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

          // 5. Backup & Restore
          Text('Backup & Restore', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          _BackupSection(),
          const SizedBox(height: 24),

          // 6. About Sakuin
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

class _BackupSection extends ConsumerWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(exportImportNotifierProvider);
    final notifier = ref.read(exportImportNotifierProvider.notifier);

    return Column(
      children: [
        // Export CSV Button
        ListTile(
          leading: Icon(Icons.file_download_outlined, color: theme.colorScheme.primary),
          title: Text('exportImport.exportCsv'.tr()),
          subtitle: Text('exportImport.exportCsvDesc'.tr()),
          trailing: state.isExporting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                )
              : const Icon(Icons.chevron_right_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: state.isExporting || state.isImporting
              ? null
              : () => notifier.pickAndExportCsv(),
        ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 4),

        // Export JSON Button
        ListTile(
          leading: Icon(Icons.backup_outlined, color: theme.colorScheme.secondary),
          title: Text('exportImport.exportJson'.tr()),
          subtitle: Text('exportImport.exportJsonDesc'.tr()),
          trailing: state.isExporting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.secondary),
                  ),
                )
              : const Icon(Icons.chevron_right_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: state.isExporting || state.isImporting
              ? null
              : () => notifier.pickAndExportJson(),
        ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 4),

        // Import Button
        ListTile(
          leading: Icon(Icons.file_upload_outlined, color: theme.colorScheme.tertiary),
          title: Text('exportImport.import'.tr()),
          subtitle: Text('exportImport.importDesc'.tr()),
          trailing: state.isImporting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.tertiary),
                  ),
                )
              : const Icon(Icons.chevron_right_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: state.isExporting || state.isImporting
              ? null
              : () => _showImportConfirmDialog(context, notifier),
        ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideX(begin: -0.1, end: 0),

        // Progress indicator
        if (state.isExporting || state.isImporting) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: state.progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(8),
          ).animate().shimmer(duration: 1000.ms),
          const SizedBox(height: 8),
          Text(
            (state.isExporting ? 'exportImport.exporting' : 'exportImport.importing').tr() +
                ' ${(state.progress * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        // Result message
        if (state.lastResult != null && !state.isExporting && !state.isImporting) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'exportImport.success'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...state.lastResult!.insertedCounts.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${e.key}: ${e.value}',
                    style: theme.textTheme.bodySmall,
                  ),
                )),
                if (state.lastResult!.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'exportImport.warnings'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ...state.lastResult!.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $w',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  )),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: notifier.clearResult,
                    child: Text('common.dismiss'.tr()),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
        ],

        // Error message
        if (state.error != null && !state.isExporting && !state.isImporting) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: notifier.clearError,
                  child: Text('common.dismiss'.tr()),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ],
    );
  }

  void _showImportConfirmDialog(BuildContext context, ExportImportNotifier notifier) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text('exportImport.importConfirmTitle'.tr())),
          ],
        ),
        content: Text('exportImport.importConfirmMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.pickAndImport();
            },
            child: Text('exportImport.importConfirmAction'.tr()),
          ),
        ],
      ),
    );
  }
}

class _CurrencyRatesSection extends ConsumerWidget {
  const _CurrencyRatesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ratesAsync = ref.watch(currencyRatesProvider);
    final repo = ref.read(currencyRepositoryProvider);

    return ratesAsync.when(
      data: (rates) => Column(
        children: rates.map((rate) {
          return ListTile(
            leading: const Icon(Icons.currency_exchange_outlined),
            title: Text('${rate.code} — ${rate.name}'),
            subtitle: rate.isBase
                ? Text('currency.base_currency'.tr())
                : Text('1 ${rate.code} = ${CurrencyFormatter.format(rate.rateToIdr, 'IDR')}'),
            trailing: rate.isBase
                ? Chip(
                    label: Text('currency.base'.tr()),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  )
                : const Icon(Icons.edit_outlined, size: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: rate.isBase
                ? null
                : () => _showEditRateDialog(context, ref, rate),
          );
        }).toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('currency.load_error'.tr()),
    );
  }

  void _showEditRateDialog(
    BuildContext context,
    WidgetRef ref,
    CurrencyRateModel rate,
  ) {
    final controller = TextEditingController(text: rate.rateToIdr.toStringAsFixed(2));
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('currency.edit_rate'.tr(namedArgs: {'code': rate.code})),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'currency.rate_to_idr'.tr(),
            prefixText: 'Rp ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              final parsed = double.tryParse(controller.text.trim().replaceAll('.', '').replaceAll(',', '.'));
              if (parsed != null && parsed > 0) {
                final repo = ref.read(currencyRepositoryProvider);
                await repo.upsertRate(
                  rate.copyWith(rateToIdr: parsed, updatedAt: DateTime.now()),
                );
              }
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }
}
