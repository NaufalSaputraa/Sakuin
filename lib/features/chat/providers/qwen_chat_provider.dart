import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/llm/model_repository.dart';
import '../../../services/llm/qwen_llm_service.dart';

/// A single turn in the on-device conversation (for context/history tracking).
class ChatTurn {
  const ChatTurn({required this.role, required this.text});

  final String role; // 'user' | 'assistant'
  final String text;
}

/// UI-facing state for the AI model download + chat lifecycle.
class QwenChatState {
  const QwenChatState({
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

  factory QwenChatState.initial(ModelState state) => QwenChatState(modelState: state);

  QwenChatState copyWith({
    ModelState? modelState,
    double? downloadProgress,
    int? downloadedMB,
    int? totalMB,
    bool? isGenerating,
    String? error,
    bool clearError = false,
    List<ChatTurn>? history,
  }) {
    return QwenChatState(
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
class QwenChatNotifier extends Notifier<QwenChatState> {
  late final ModelRepository _repo;

  @override
  QwenChatState build() {
    _repo = ref.watch(modelRepositoryProvider);

    // Keep modelState in sync with the repository stream.
    ref.listen<AsyncValue<ModelState>>(modelStateStreamProvider, (_, next) {
      next.whenData((s) {
        state = state.copyWith(modelState: s, clearError: s != ModelState.error);
      });
    });

    return QwenChatState.initial(_repo.currentState);
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

  /// Generates a response using the on-device Qwen model.
  /// Returns the reply text, or an empty string on failure (caller should
  /// fall back to the deterministic rule-based path).
  Future<String> generate({
    required String userPrompt,
    required String financialContext,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    final service = ref.read(qwenLlmServiceProvider);
    final fullPrompt = '$financialContext\n\nUser question: $userPrompt';
    final result = await service.generateResponse(userPrompt: fullPrompt);
    state = state.copyWith(isGenerating: false);

    return result.when(
      success: (text) {
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

final qwenChatNotifierProvider =
    NotifierProvider<QwenChatNotifier, QwenChatState>(() {
  return QwenChatNotifier();
});
