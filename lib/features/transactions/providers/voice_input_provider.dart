import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/result.dart';
import '../../../services/voice/speech_service.dart';
import '../../../services/ml/parsed_transaction.dart';
import '../../../services/ml/text_parser_service.dart';

class VoiceInputState {
  final bool isListening;
  final String transcript;
  final ParsedTransaction? parsed;
  final String? error; // localized key (e.g. 'voice.errorPermission')
  final double confidence;

  const VoiceInputState({
    this.isListening = false,
    this.transcript = '',
    this.parsed,
    this.error,
    this.confidence = 0.0,
  });

  VoiceInputState copyWith({
    bool? isListening,
    String? transcript,
    ParsedTransaction? parsed,
    String? error,
    double? confidence,
    bool clearError = false,
    bool clearParsed = false,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      transcript: transcript ?? this.transcript,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      error: clearError ? null : (error ?? this.error),
      confidence: confidence ?? this.confidence,
    );
  }
}

class VoiceInputNotifier extends Notifier<VoiceInputState> {
  Timer? _debounceTimer;

  @override
  VoiceInputState build() => const VoiceInputState();

  /// Starts listening. Each debounced transcript is parsed into a
  /// [ParsedTransaction] and stored in [VoiceInputState.parsed].
  Future<void> start() async {
    if (state.isListening) return;
    state = state.copyWith(
      isListening: true,
      error: null,
      clearParsed: true,
      transcript: '',
      confidence: 0.0,
    );

    final speech = ref.read(speechServiceProvider);
    final result = await speech.startListening(
      onResult: _handleTranscript,
    );

    if (result.isFailure) {
      final err = result.errorOrNull!;
      state = state.copyWith(
        isListening: false,
        error: err is PermissionError ? 'voice.errorPermission' : 'voice.errorInit',
        clearParsed: true,
      );
    }
  }

  void _handleTranscript(String transcript) {
    state = state.copyWith(transcript: transcript, error: null);

    // Debounce 400ms before parsing to avoid thrashing the parser pipeline.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _parseTranscript(transcript);
    });
  }

  Future<void> _parseTranscript(String transcript) async {
    final parser = ref.read(textParserServiceProvider);

    final parsed = await parser.parseText(text: transcript);

    // Ignore stale parses if a newer transcript has since arrived.
    if (state.transcript != transcript) return;

    state = state.copyWith(parsed: parsed, confidence: parsed.confidence);
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final speech = ref.read(speechServiceProvider);
    await speech.stop();
    state = state.copyWith(isListening: false);
  }

  void clear() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    state = const VoiceInputState();
  }
}

final voiceInputProvider =
    NotifierProvider<VoiceInputNotifier, VoiceInputState>(() {
  return VoiceInputNotifier();
});
