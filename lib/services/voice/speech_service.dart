import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/utils/result.dart';

/// Wraps the `speech_to_text` plugin into a single on-device STT pipeline.
///
/// All public methods return structured types (never a raw [Map]):
/// - [initialize] returns a plain [bool] (engine ready or not).
/// - [startListening] returns a [Result<String, AppError>] so callers can
///   handle the permission gate / init failure via the [Result] pattern.
/// - [stop] and [isListening] are plain accessors.
///
/// Transcripts are **debounced** (400ms) before being forwarded to [onResult]
/// so consumers are not flooded with partial results on every frame. A final
/// result is always emitted immediately.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  Timer? _debounceTimer;
  String _pendingTranscript = '';

  bool get isListening => _isListening;

  /// Initializes the STT engine and requests microphone permission.
  /// Returns `true` if the engine is ready to listen.
  Future<bool> initialize() async {
    try {
      final available = await _speech.initialize(
        onError: (error) =>
            debugPrint('[SpeechService] init error: ${error.errorMsg}'),
      );
      return available;
    } on Exception catch (e) {
      debugPrint('[SpeechService] initialize failed: $e');
      return false;
    }
  }

  /// Starts streaming on-device speech recognition.
  ///
  /// [onResult] is invoked with the latest debounced transcript.
  /// Returns:
  /// - [Success] once listening has started (value: status string).
  /// - [Failure] with [PermissionError] if mic permission is denied or the
  ///   engine is unavailable, or [AppError.parse] if listening could not start.
  Future<Result<String, AppError>> startListening({
    required void Function(String transcript) onResult,
  }) async {
    final ready = await initialize();
    if (!ready) {
      _isListening = false;
      return const Failure(
        PermissionError(
          'Microphone permission denied or STT engine unavailable',
        ),
      );
    }

    _isListening = true;
    _pendingTranscript = '';

    try {
      await _speech.listen(
        onResult: (result) {
          final transcript = result.recognizedWords;
          if (transcript.isEmpty) return;
          _pendingTranscript = transcript;

          // Final result: emit immediately, no debounce.
          if (result.finalResult) {
            _debounceTimer?.cancel();
            _emit(onResult);
            return;
          }

          // Partial result: debounce 400ms (resets on every new partial).
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 400), () {
            _emit(onResult);
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          localeId: 'id_ID',
          cancelOnError: true,
          onDevice: true,
        ),
      );
      return const Success('listening');
    } on Exception catch (e) {
      debugPrint('[SpeechService] listen failed: $e');
      _isListening = false;
      return Failure(AppError.parse('Failed to start listening: $e'));
    }
  }

  /// Stops the active recognition session and cancels any pending debounce.
  Future<void> stop() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_isListening) {
      try {
        await _speech.stop();
      } on Exception catch (e) {
        debugPrint('[SpeechService] stop failed: $e');
      }
      _isListening = false;
    }
  }

  void _emit(void Function(String transcript) onResult) {
    if (_pendingTranscript.isNotEmpty) {
      onResult(_pendingTranscript);
    }
  }
}

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});
