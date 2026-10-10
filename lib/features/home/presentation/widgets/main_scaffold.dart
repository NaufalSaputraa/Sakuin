import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/presentation/quick_entry_sheet.dart';
import '../../../share/providers/share_import_provider.dart';
import '../../../../services/notifications/mutation_notification_listener_service.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void initState() {
    super.initState();
    // Share Import & Mutation Detector:
    // Check pending intents when scaffold first appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openSharedEntry(ref.read(shareImportProvider));
      ref.read(mutationDetectorProvider.notifier).init();
    });
  }

  void _openSharedEntry(ShareImportState shareState) {
    if (!shareState.hasPending) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('share.received'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
    QuickEntrySheet.show(context, initialText: shareState.sharedText);
  }

  void _showMutationPrompt(IncomingMutationNotification mutation) {
    final parsed = mutation.parsedTransaction;
    final amountText = (parsed != null && parsed.hasAmount)
        ? RupiahFormatter.format(parsed.amount!)
        : '';
    final sourceName =
        mutation.title.isNotEmpty ? mutation.title : mutation.packageName;
    final detailText = (parsed != null && parsed.title.isNotEmpty)
        ? '${parsed.title} ($amountText)'
        : (amountText.isNotEmpty ? amountText : mutation.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'settings.mutation_detected_title'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'settings.mutation_detected_body'.tr(namedArgs: {
                'source': sourceName,
                'detail': detailText,
              }),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'settings.mutation_record_now'.tr(),
          onPressed: () {
            ref.read(mutationDetectorProvider.notifier).dismissPending();
            QuickEntrySheet.show(
              context,
              initialParsed: parsed,
              initialText: (parsed == null || !parsed.hasAmount)
                  ? mutation.text
                  : null,
            );
          },
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/analytics')) return 1;
    if (location.startsWith('/chat')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/analytics');
        break;
      case 2:
        context.go('/chat');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Share Import: open the entry sheet whenever a new shared text
    // arrives while the app is running (warm start).
    ref.listen<ShareImportState>(shareImportProvider, (prev, next) {
      if (next.hasPending && next.sharedText != prev?.sharedText) {
        _openSharedEntry(next);
      }
    });

    // Auto-detect mutation: notify user when incoming banking/e-wallet notification is intercepted
    ref.listen<MutationDetectorState>(mutationDetectorProvider, (prev, next) {
      final mutation = next.pendingMutation;
      if (mutation != null && mutation != prev?.pendingMutation) {
        _showMutationPrompt(mutation);
      }
    });

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              // Pennywise-style haze: semi-transparent surface with tinted overlay
              color: isDark
                  ? colorScheme.surface.withValues(alpha: 0.75)
                  : colorScheme.surface.withValues(alpha: 0.82),
              // Subtle top border for definition
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavBarItem(
                      icon: Icons.home_rounded,
                      label: 'nav.home'.tr(),
                      isSelected: selectedIndex == 0,
                      onTap: () => _onItemTapped(0, context),
                    ),
                    _NavBarItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'nav.analytics'.tr(),
                      isSelected: selectedIndex == 1,
                      onTap: () => _onItemTapped(1, context),
                    ),
                    _NavBarItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'nav.chat'.tr(),
                      isSelected: selectedIndex == 2,
                      onTap: () => _onItemTapped(2, context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.65)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
