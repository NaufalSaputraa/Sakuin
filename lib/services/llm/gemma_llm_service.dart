import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:litertlm/litertlm.dart';

import '../../../core/utils/result.dart';
import 'model_repository.dart';

/// On-device LLM service backed by LiteRT (`litertlm`) running the
/// Gemma 4 E2B `.litertlm` model (~2.39 GB, HuggingFace soniqo). The model
/// is loaded lazily from an external file (never from assets) once it has
/// been downloaded and verified by [ModelRepository].
///
/// Inference is gated: calling [generateResponse] before the model is
/// downloaded returns a [Failure] instructing the user to download it
/// from Settings.
class GemmaLlmService {
  GemmaLlmService(this._modelRepository);

  final ModelRepository _modelRepository;

  /// System prompt tuned for Gemma 4 E2B — ramah, informatif, dan bisa edit DB via tools.
  static const String _systemInstruction = '''
Kamu adalah Sakuin AI, sahabat keuangan Indonesia yang ramah dan informatif 🙏.
- Nada: hangat, suportif, jelas, tidak kaku. Pakai "kamu" bukan "anda", sesekali emoji yang relevan.
- Paham format Rupiah: Rp 50.000 (titik pemisah ribuan, tanpa desimal).
- Paham singkatan Indonesia: 25rb = 25000, 1.5jt = 1500000, 500k = 500000.
- Kategori: Pulsa, Ojol, Warung, Kos, BBM, Makanan, Transport, Belanja, Tagihan, dll. (16 kategori + custom).
- Jika user minta "tambahkan batch pengeluaran" atau "edit database", JANGAN jawab teks biasa — tapi output JSON tool call:
  {"tool": "addBatchTransactions", "args": {"transactions": [{"amount": 20000, "category": "warung", "title": "Warung Kopi", "wallet": "gopay"}, {"amount": 15000, "category": "pulsa", "title": "Pulsa"}]}}
  Atau {"tool": "addTransaction", "args": {"amount": 50000, "category": "makanan", "title": "Makan Siang"}}
  Atau {"tool": "getWallets", "args": {}} / {"tool": "getCategories", "args": {}}
- Selain tool call, jawab singkat, informatif, dan tawarkan bantuan lanjutan.
- Selalu format angka uang sebagai Rp dengan titik pemisah ribuan (contoh: Rp 50.000).
- Perlakukan angka keuangan dari konteks prompt sebagai fakta mutlak. Jangan mengarang transaksi/saldo.
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
            backend: const Backend.gpu(),
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
              backend: const Backend.cpu(),
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
      final text = response.text.trim();
      final toolCall = _parseToolCall(text);
      if (toolCall != null) {
        return Success('__TOOL__:${jsonEncode(toolCall)}');
      }
      return Success(text);
    } on LiteRtLmException catch (e) {
      return Failure(AppError.parse('Generation failed: ${e.message}'));
    } catch (e) {
      return Failure(AppError.parse('Generation failed: $e'));
    }
  }

  /// Parses a tool call JSON from Gemma response if present.
  Map<String, dynamic>? _parseToolCall(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('{') || !trimmed.contains('"tool"')) return null;
    try {
      final jsonStart = trimmed.indexOf('{');
      final jsonEnd = trimmed.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return null;
      final jsonStr = trimmed.substring(jsonStart, jsonEnd + 1);
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic> && decoded.containsKey('tool')) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _conversation?.dispose();
    _engine?.dispose();
    _conversation = null;
    _engine = null;
  }
}

/// Provider for the on-device [GemmaLlmService].
final gemmaLlmServiceProvider = Provider<GemmaLlmService>((ref) {
  final repo = ref.watch(modelRepositoryProvider);
  final service = GemmaLlmService(repo);
  ref.onDispose(service.dispose);
  return service;
});
