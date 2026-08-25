import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/presentation/quick_entry_sheet.dart';
import '../../../share/providers/share_import_provider.dart';

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
    // Share Import: if a shared text is already pending when the scaffold
    // first appears (e.g. cold start), open the entry sheet for it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openSharedEntry(ref.read(shareImportProvider));
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
