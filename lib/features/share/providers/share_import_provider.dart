import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/ml/parsed_transaction.dart';
import '../../../services/ml/text_parser_service.dart';
import '../../../services/share/share_import_service.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/providers/category_providers.dart';
import '../../wallets/domain/wallet_model.dart';
import '../../wallets/providers/wallet_providers.dart';

/// State for the Share Import feature.
///
/// [sharedText] is the raw text shared from another app (banking /
/// e-wallet) and [parsed] is the result of running it through
/// [TextParserService]. Empty state means there is nothing pending.
class ShareImportState {
  final String? sharedText;
  final ParsedTransaction? parsed;

  const ShareImportState({this.sharedText, this.parsed});

  bool get hasPending => sharedText != null && sharedText!.isNotEmpty;
}

/// Watches [ShareImportService] and auto-parses every incoming shared text
/// into a [ParsedTransaction] so consumers (QuickEntrySheet) can auto-fill.
class ShareImportNotifier extends Notifier<ShareImportState> {
  StreamSubscription<String>? _subscription;
  bool _initialized = false;

  @override
  ShareImportState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    return const ShareImportState();
  }

  /// Cold start entry point — called once from the app root at startup.
  ///
  /// Subscribes the warm-start stream for the whole session and checks for
  /// a text shared while the app was closed. The native intent is reset
  /// right after it has been handled so it is not re-delivered later.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final service = ref.read(shareImportServiceProvider);

    // Warm start: shares arriving while the app is alive.
    _subscription ??= service.watchSharedText().listen(_handleSharedText);

    // Cold start: app may have been launched by a SHARE intent.
    final result = await service.getInitialSharedText();
    final initialText = result.valueOrNull;
    if (initialText != null && initialText.isNotEmpty) {
      await _handleSharedText(initialText);
    }

    // Reset so the same intent is not re-delivered on next launch.
    service.reset();
  }

  Future<void> _handleSharedText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (state.sharedText == trimmed) return; // duplicate guard

    final parser = ref.read(textParserServiceProvider);
    final wallets =
        ref.read(allWalletsProvider).asData?.value ?? <WalletModel>[];
    final categories =
        ref.read(allCategoriesProvider).asData?.value ?? <CategoryModel>[];

    final parsed = await parser.parseText(
      text: trimmed,
      availableWallets: wallets,
      availableCategories: categories,
    );

    state = ShareImportState(sharedText: trimmed, parsed: parsed);
  }

  /// Marks the current share as handled (called by QuickEntrySheet after
  /// auto-filling) and clears the native intent.
  void consume() {
    state = const ShareImportState();
    ref.read(shareImportServiceProvider).reset();
  }
}

final shareImportProvider =
    NotifierProvider<ShareImportNotifier, ShareImportState>(() {
  return ShareImportNotifier();
});
