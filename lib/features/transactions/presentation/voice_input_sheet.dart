import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/ml/parsed_transaction.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/providers/category_providers.dart';
import '../providers/voice_input_provider.dart';

class VoiceInputSheet extends ConsumerStatefulWidget {
  const VoiceInputSheet({super.key});

  /// Shows the voice input sheet and returns the parsed result (or null).
  static Future<ParsedTransaction?> show(BuildContext context) {
    return showModalBottomSheet<ParsedTransaction?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceInputSheet(),
    );
  }

  @override
  ConsumerState<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<VoiceInputSheet> {
  @override
  void initState() {
    super.initState();
    // Reset any previous result and begin listening immediately.
    ref.read(voiceInputProvider.notifier).clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceInputProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    ref.read(voiceInputProvider.notifier).stop();
    super.dispose();
  }

  String _categoryLabel(String? key) {
    if (key == null) return '-';
    final categories =
        ref.read(allCategoriesProvider).asData?.value ?? <CategoryModel>[];
    final match = categories.where((c) => c.key == key).firstOrNull;
    if (match == null) return key;
    return match.localizedName(context.locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(voiceInputProvider);
    final notifier = ref.read(voiceInputProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header / listening indicator
            Row(
              children: [
                if (state.isListening)
                  const _ListeningIndicator()
                else
                  Icon(
                    Icons.mic_off_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.isListening
                        ? 'voice.listening'.tr()
                        : 'voice.tapToSpeak'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Error banner
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (state.error != null) const SizedBox(height: 16),

            // Transcript
            Text(
              'voice.transcript'.tr(),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                state.transcript.isEmpty
                    ? 'voice.tapToSpeak'.tr()
                    : state.transcript,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: state.transcript.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                  color: state.transcript.isEmpty
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Parsed result fields
            if (state.parsed != null) ...[
              Text(
                'voice.parsed'.tr(),
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              _ParsedField(
                label: 'input.amount'.tr(),
                value: RupiahFormatter.format(state.parsed!.amount ?? 0),
                valueColor: theme.colorScheme.primary,
              ),
              _ParsedField(
                label: 'input.title'.tr(),
                value: state.parsed!.title,
              ),
              _ParsedField(
                label: 'input.category'.tr(),
                value: _categoryLabel(state.parsed!.categoryKey),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(state.parsed),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('voice.useResult'.tr()),
              ),
            ] else ...[
              const SizedBox(height: 8),
              if (state.isListening)
                Center(
                  child: Text(
                    'voice.listening'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
            const SizedBox(height: 12),

            // Stop button
            if (state.isListening)
              OutlinedButton.icon(
                onPressed: notifier.stop,
                icon: const Icon(Icons.stop_rounded),
                label: Text('voice.stop'.tr()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListeningIndicator extends StatelessWidget {
  const _ListeningIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Icon(
      Icons.mic_rounded,
      color: theme.colorScheme.primary,
      size: 28,
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          duration: 600.ms,
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.25, 1.25),
        );
  }
}

class _ParsedField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ParsedField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
