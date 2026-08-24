import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/model_download_constants.dart';
import '../../../services/llm/model_repository.dart';
import '../../chat/providers/gemma_chat_provider.dart';

/// Settings section that drives the on-device LLM model download/status.
/// Single source of truth for download UI (progress, retry, insufficient
/// space). The chat screen only consumes the resulting state.
class AiModelSection extends ConsumerWidget {
  const AiModelSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(gemmaChatNotifierProvider);
    final notifier = ref.read(gemmaChatNotifierProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'llm.modelTitle'.tr(),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ModelDownloadConfig.displayName} • ${ModelDownloadConfig.displaySize}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(modelState: state.modelState),
              ],
            ),
            const SizedBox(height: 14),
            _body(context, state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, GemmaChatState state, GemmaChatNotifier notifier) {
    final theme = Theme.of(context);
    switch (state.modelState) {
      case ModelState.notDownloaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('llm.notDownloadedDesc'.tr(), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => notifier.startDownload(),
              icon: const Icon(Icons.download_rounded),
              label: Text('llm.downloadButton'.tr()),
            ),
          ],
        );

      case ModelState.downloading:
        final pct = (state.downloadProgress * 100).toInt();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: state.downloadProgress > 0 ? state.downloadProgress : null,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              '${'llm.downloading'.tr()} ${state.downloadedMB} / ${state.totalMB} MB ($pct%)',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => notifier.cancelDownload(),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text('llm.cancel'.tr()),
            ),
          ],
        );

      case ModelState.loading:
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('llm.loading'.tr(), style: theme.textTheme.bodySmall),
          ],
        );

      case ModelState.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('llm.readyDesc'.tr(), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => context.push('/chat'),
              icon: const Icon(Icons.chat_rounded),
              label: Text('llm.openChat'.tr()),
            ),
          ],
        );

      case ModelState.error:
        final err = state.error;
        final isSpace = err == 'llm.insufficientSpace';
        final msg = (err != null && err.startsWith('llm.'))
            ? err.tr()
            : (err ?? 'llm.errorGeneric'.tr());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
            if (isSpace) ...[
              const SizedBox(height: 12),
              Text('llm.insufficientSpaceHint'.tr(), style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => notifier.startDownload(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('llm.retry'.tr()),
            ),
          ],
        );
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.modelState});
  final ModelState modelState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (String label, Color bg) = switch (modelState) {
      ModelState.notDownloaded => (
        'llm.notDownloaded'.tr(),
        theme.colorScheme.surfaceContainerHighest,
      ),
      ModelState.downloading => (
        'llm.downloading'.tr(),
        theme.colorScheme.primaryContainer,
      ),
      ModelState.loading => (
        'llm.loading'.tr(),
        theme.colorScheme.tertiaryContainer,
      ),
      ModelState.ready => (
        'llm.ready'.tr(),
        theme.colorScheme.primaryContainer,
      ),
      ModelState.error => (
        'llm.error'.tr(),
        theme.colorScheme.errorContainer,
      ),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: bg,
      visualDensity: VisualDensity.compact,
    );
  }
}
