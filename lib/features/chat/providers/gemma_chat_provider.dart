import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../services/llm/model_repository.dart';
import '../../../services/llm/gemma_llm_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/providers/transaction_providers.dart';

/// A single turn in the on-device conversation (for context/history tracking).
class ChatTurn {
  const ChatTurn({required this.role, required this.text});

  final String role; // 'user' | 'assistant'
  final String text;
}

/// UI-facing state for the AI model download + chat lifecycle.
class GemmaChatState {
  const GemmaChatState({
    required this.modelState,
    this.downloadProgress = 0.0,
    this.downloadedMB = 0,
    this.totalMB = 0,
    this.isGenerating = false,
    this.error,
    this.history = const [],
  });

  final ModelState modelState;
  final double downloadProgress; // 0.0 .. 1.0
  final int downloadedMB;
  final int totalMB;
  final bool isGenerating;
  final String? error;
  final List<ChatTurn> history;

  factory GemmaChatState.initial(ModelState state) => GemmaChatState(modelState: state);

  GemmaChatState copyWith({
    ModelState? modelState,
    double? downloadProgress,
    int? downloadedMB,
    int? totalMB,
    bool? isGenerating,
    String? error,
    bool clearError = false,
    List<ChatTurn>? history,
  }) {
    return GemmaChatState(
      modelState: modelState ?? this.modelState,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedMB: downloadedMB ?? this.downloadedMB,
      totalMB: totalMB ?? this.totalMB,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      history: history ?? this.history,
    );
  }
}

/// Notifier coordinating model download state and on-device generation.
class GemmaChatNotifier extends Notifier<GemmaChatState> {
  late final ModelRepository _repo;

  @override
  GemmaChatState build() {
    _repo = ref.watch(modelRepositoryProvider);

    // Keep modelState in sync with the repository stream.
    ref.listen<AsyncValue<ModelState>>(modelStateStreamProvider, (_, next) {
      next.whenData((s) {
        state = state.copyWith(modelState: s, clearError: s != ModelState.error);
      });
    });

    return GemmaChatState.initial(_repo.currentState);
  }

  Future<void> startDownload() async {
    state = state.copyWith(
      downloadProgress: 0.0,
      downloadedMB: 0,
      totalMB: 0,
      clearError: true,
    );
    final result = await _repo.startDownload(
      onProgress: (received, total) {
        final totalMb = (total / (1024 * 1024)).round();
        final receivedMb = (received / (1024 * 1024)).round();
        final progress = total > 0 ? received / total : 0.0;
        state = state.copyWith(
          downloadedMB: receivedMb,
          totalMB: totalMb,
          downloadProgress: progress,
        );
      },
    );
    if (result.isFailure) {
      state = state.copyWith(error: result.errorOrNull?.message);
    }
  }

  void cancelDownload() {
    _repo.cancelDownload();
  }

  Future<void> refreshModelState() async {
    await _repo.refreshModelState();
  }

  /// Generates a response using the on-device Gemma model.
  /// Handles tool calls (e.g. addBatchTransactions) with a friendly confirmation.
  Future<String> generate({
    required String userPrompt,
    required String financialContext,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    final service = ref.read(gemmaLlmServiceProvider);
    final fullPrompt = '$financialContext\n\nUser question: $userPrompt';
    final result = await service.generateResponse(userPrompt: fullPrompt);
    state = state.copyWith(isGenerating: false);

    return result.when(
      success: (text) async {
        // Tool calling: Gemma returns "__TOOL__:{json}" for DB edits
        if (text.startsWith('__TOOL__:')) {
          final jsonStr = text.substring('__TOOL__:'.length);
          try {
            final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
            final tool = decoded['tool'] as String?;
            final args = decoded['args'] as Map<String, dynamic>?;
            if (tool == 'addBatchTransactions' && args != null) {
              final txs = (args['transactions'] as List).cast<Map<String, dynamic>>();
              final repo = ref.read(transactionRepositoryProvider);
              final db = ref.read(databaseProvider);
              // Use first wallet as target (or let repository pick default)
              final wallets = await db.walletDao.getAll();
              final targetWalletId = wallets.isNotEmpty ? wallets.first.id : 1;
              int added = 0;
              for (final tx in txs) {
                final amount = (tx['amount'] as num).toDouble();
                final category = tx['category'] as String? ?? 'other_expense';
                final title = tx['title'] as String? ?? 'Transaksi';
                // Resolve category id
                final cat = await db.categoryDao.getByKey(category);
                await repo.createTransaction(
                  walletId: targetWalletId,
                  categoryId: cat?.id,
                  amount: amount,
                  title: title,
                  transactionType: TransactionType.expense,
                );
                added++;
              }
              final friendly =
                  'Siap! $added pengeluaran sudah aku tambahkan 🙏 (${txs.map((e) => e['title']).join(', ')}). Mau aku ringkas pengeluaran hari ini?';
              state = state.copyWith(
                history: [
                  ...state.history,
                  ChatTurn(role: 'user', text: userPrompt),
                  ChatTurn(role: 'assistant', text: friendly),
                ],
              );
              return friendly;
            } else if (tool == 'addTransaction' && args != null) {
              final repo = ref.read(transactionRepositoryProvider);
              final db = ref.read(databaseProvider);
              final wallets = await db.walletDao.getAll();
              final targetWalletId = wallets.isNotEmpty ? wallets.first.id : 1;
              final amount = (args['amount'] as num).toDouble();
              final category = args['category'] as String? ?? 'other_expense';
              final title = args['title'] as String? ?? 'Transaksi';
              final cat = await db.categoryDao.getByKey(category);
              await repo.createTransaction(
                walletId: targetWalletId,
                categoryId: cat?.id,
                amount: amount,
                title: title,
                transactionType: TransactionType.expense,
              );
              final friendly = 'Berhasil! "$title" Rp ${amount.toStringAsFixed(0)} sudah aku catat di $category ✨';
              state = state.copyWith(
                history: [
                  ...state.history,
                  ChatTurn(role: 'user', text: userPrompt),
                  ChatTurn(role: 'assistant', text: friendly),
                ],
              );
              return friendly;
            }
          } catch (e) {
            // Fall through to plain text on parse error
          }
        }
        state = state.copyWith(
          history: [
            ...state.history,
            ChatTurn(role: 'user', text: userPrompt),
            ChatTurn(role: 'assistant', text: text),
          ],
        );
        return text;
      },
      failure: (err) {
        state = state.copyWith(error: err.message);
        return '';
      },
    );
  }
}

final gemmaChatNotifierProvider =
    NotifierProvider<GemmaChatNotifier, GemmaChatState>(() {
  return GemmaChatNotifier();
});
