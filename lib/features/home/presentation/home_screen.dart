import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'widgets/balance_hero_card.dart';
import 'widgets/budget_progress_widget.dart';
import 'widgets/recent_transactions_section.dart';
import 'widgets/wallet_list_section.dart';
import 'widgets/activity_heatmap_widget.dart';
import 'widgets/smart_input_bar.dart';
import '../../transactions/presentation/quick_entry_sheet.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../../budget/providers/budget_providers.dart';
import '../../../services/ocr/receipt_scanner_service.dart';
import '../../../services/shortcuts/quick_actions_service.dart';
import '../../../services/widgets/home_widget_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final QuickActionsService _quickActionsService = QuickActionsService();

  @override
  void initState() {
    super.initState();
    _initQuickActions();
    // Initial home-widget sync after first frame (providers may still be
    // loading). Subsequent syncs are driven by ref.listen below.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncWidgetData();
    });
  }

  void _initQuickActions() {
    _quickActionsService.init((action) async {
      if (!mounted) return;

      switch (action) {
        case QuickActionType.quickEntry:
          await QuickEntrySheet.show(context);
          break;
        case QuickActionType.scanReceipt:
          final scanner = ref.read(receiptScannerServiceProvider);
          final result = await scanner.scanReceiptFromSource(source: ReceiptSource.camera);
          if (result != null && mounted) {
            await QuickEntrySheet.show(
              context,
              initialText: '${result.title} ${result.amount != null ? result.amount!.toInt() : ""}',
            );
          }
          break;
        case QuickActionType.aiChat:
          context.go('/chat');
          break;
      }
    });
  }

  void _showScanOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                Text(
                  'Scan Struk / Bukti Pembayaran',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Mendukung struk fisik kertas dan screenshot e-wallet/m-banking online.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary),
                  ),
                  title: const Text('Foto Struk Fisik (Kamera)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Indomaret, SPBU, Restoran, Supermarket'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final scanner = ref.read(receiptScannerServiceProvider);
                    final result = await scanner.scanReceiptFromSource(source: ReceiptSource.camera);
                    if (result != null && context.mounted) {
                      await QuickEntrySheet.show(
                        context,
                        initialText: '${result.title} ${result.amount != null ? result.amount!.toInt() : ""}',
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary),
                  ),
                  title: const Text('Pilih Bukti Online / E-Receipt (Galeri)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Screenshot Transfer BCA, GoPay, OVO, ShopeePay'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final scanner = ref.read(receiptScannerServiceProvider);
                    final result = await scanner.scanReceiptFromSource(source: ReceiptSource.gallery);
                    if (result != null && context.mounted) {
                      await QuickEntrySheet.show(
                        context,
                        initialText: '${result.title} ${result.amount != null ? result.amount!.toInt() : ""}',
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _syncWidgetData() {
    // Use ref.read (not ref.watch) — this is invoked from listeners /
    // post-frame callback, never during build.
    final balance = ref.read(totalBalanceProvider).asData?.value ?? 0.0;
    final expense = ref.read(currentMonthExpenseProvider).asData?.value ?? 0.0;
    final budget = ref.read(primaryBudgetProvider).asData?.value;
    final limit = budget?.amount ?? 3000000.0;
    final remaining = limit - expense;
    final recent = ref.read(recentTransactionsProvider).asData?.value;
    final latest = recent?.firstOrNull;

    HomeWidgetService.updateWidgetData(
      totalBalance: balance,
      remainingBudget: remaining,
      latestTransactionTitle: latest?.title,
      latestTransactionAmount: latest?.amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sync home-screen widget data reactively — only when the underlying
    // providers actually change — instead of running a side-effect on every
    // rebuild (which caused main-thread jank). This also decouples HomeScreen
    // rebuilds from balance/expense/budget changes.
    ref.listen(totalBalanceProvider, (_, _) => _syncWidgetData());
    ref.listen(currentMonthExpenseProvider, (_, _) => _syncWidgetData());
    ref.listen(primaryBudgetProvider, (_, _) => _syncWidgetData());
    ref.listen(recentTransactionsProvider, (_, _) => _syncWidgetData());

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'app_name'.tr(),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    Text(
                                      'app_tagline'.tr(),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.language_rounded),
                                  onPressed: () {
                                    final currentLocale = context.locale.languageCode;
                                    context.setLocale(
                                      currentLocale == 'en' ? const Locale('id') : const Locale('en'),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings_outlined),
                                  onPressed: () => context.push('/settings'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Balance Hero Card (NumberFlow animation)
                        const RepaintBoundary(child: BalanceHeroCard()),
                        const SizedBox(height: 16),

                        // Budget Progress Widget (NumberFlow + progress ring)
                        const RepaintBoundary(child: BudgetProgressWidget()),
                        const SizedBox(height: 24),

                        // Recent Transactions List
                        RepaintBoundary(
                          child: RecentTransactionsSection(
                            onViewAllTap: () => context.go('/analytics'),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Wallets Carousel
                        const RepaintBoundary(child: WalletListSection()),
                        const SizedBox(height: 24),

                        // Activity Heatmap Grid
                        const RepaintBoundary(child: ActivityHeatmapWidget()),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Sticky Bottom Input Zone (FAB + Smart Input Bar)
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.small(
                    onPressed: () {
                      QuickEntrySheet.show(context, startInNumpadMode: true);
                    },
                    child: const Icon(Icons.add_rounded, size: 24),
                  ),
                  const SizedBox(height: 10),
                  SmartInputBar(
                    onTap: () {
                      QuickEntrySheet.show(context);
                    },
                    onCameraTap: () {
                      _showScanOptions(context, ref);
                    },
                    useBlur: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
