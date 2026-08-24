import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:litertlm/litertlm.dart';

import '../../../core/utils/result.dart';
import 'model_repository.dart';

/// On-device LLM service backed by LiteRT (`litertlm`) running the
/// Qwen2.5-1.5B-Instruct `.litertlm` model. The model is loaded lazily
/// from an external file (never from assets) once it has been downloaded
/// and verified by [ModelRepository].
///
/// Inference is gated: calling [generateResponse] before the model is
/// downloaded returns a [Failure] instructing the user to download it
/// from Settings.
class QwenLlmService {
  QwenLlmService(this._modelRepository);

  final ModelRepository _modelRepository;

  static const String _systemInstruction = '''
You are Sakuin AI, an on-device personal finance assistant for Indonesian users.
- Answer concisely and helpfully in the user's language (Bahasa Indonesia or English).
- Treat the financial figures provided in the prompt as absolute facts.
- Never invent transactions, balances, or categories.
- You only give advice and explanations; you cannot write to the database.
''';

  Engine? _engine;
  Conversation? _conversation;
  ModelState _status = ModelState.notDownloaded;

  ModelState get status => _status;

  Future<bool> isModelDownloaded() => _modelRepository.isModelDownloaded();

  /// Generates a response for [userPrompt]. Lazily initializes the engine
  /// (GPU with CPU fallback) on first call.
  Future<Result<String, AppError>> generateResponse({
    required String userPrompt,
  }) async {
    final downloaded = await _modelRepository.isModelDownloaded();
    if (!downloaded) {
      return Failure(
        AppError.notFound('Please download the AI model from Settings.'),
      );
    }

    if (_engine == null) {
      _status = ModelState.loading;
      final path = await _modelRepository.getModelPath();
      try {
        _engine = Engine(
          engineConfig: EngineConfig(
            modelPath: path,
            backend: Backend.gpu(),
            maxNumTokens: 1024,
          ),
        );
        await _engine!.initialize();
      } on LiteRtLmException {
        // GPU unavailable (e.g. emulator) — fall back to CPU.
        try {
          _engine = Engine(
            engineConfig: EngineConfig(
              modelPath: path,
              backend: Backend.cpu(),
              maxNumTokens: 1024,
            ),
          );
          await _engine!.initialize();
        } on LiteRtLmException catch (e) {
          _status = ModelState.error;
          return Failure(AppError.parse('Engine init failed: ${e.message}'));
        }
      } catch (e) {
        _status = ModelState.error;
        return Failure(AppError.parse('Engine init failed: $e'));
      }

      try {
        _conversation = await _engine!.createConversation(
          ConversationConfig(
            systemMessage: Message.system(_systemInstruction),
          ),
        );
      } on LiteRtLmException catch (e) {
        _status = ModelState.error;
        return Failure(AppError.parse('Conversation init failed: ${e.message}'));
      }
      _status = ModelState.ready;
    }

    try {
      final response = await _conversation!.sendMessage(
        Message.user(userPrompt),
      );
      return Success(response.text);
    } on LiteRtLmException catch (e) {
      return Failure(AppError.parse('Generation failed: ${e.message}'));
    } catch (e) {
      return Failure(AppError.parse('Generation failed: $e'));
    }
  }

  void dispose() {
    _conversation?.dispose();
    _engine?.dispose();
    _conversation = null;
    _engine = null;
  }
}

/// Provider for the on-device [QwenLlmService].
final qwenLlmServiceProvider = Provider<QwenLlmService>((ref) {
  final repo = ref.watch(modelRepositoryProvider);
  final service = QwenLlmService(repo);
  ref.onDispose(service.dispose);
  return service;
});
