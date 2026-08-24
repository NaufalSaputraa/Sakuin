import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/ml/parsed_transaction.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/providers/category_providers.dart';
import '../providers/receipt_scan_provider.dart';

class ReceiptScanSheet extends ConsumerStatefulWidget {
  const ReceiptScanSheet({super.key});

  /// Shows the OCR receipt sheet and returns the parsed result (or null).
  static Future<ParsedTransaction?> show(BuildContext context) {
    return showModalBottomSheet<ParsedTransaction?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReceiptScanSheet(),
    );
  }

  @override
  ConsumerState<ReceiptScanSheet> createState() => _ReceiptScanSheetState();
}

class _ReceiptScanSheetState extends ConsumerState<ReceiptScanSheet> {
  @override
  void initState() {
    super.initState();
    // Reset any previous scan result when the sheet is (re)opened.
    ref.read(receiptScanProvider.notifier).clear();
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
    final state = ref.watch(receiptScanProvider);
    final notifier = ref.read(receiptScanProvider.notifier);

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
            Text(
              'ocr.cameraTitle'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Source buttons
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'ocr.pickCamera'.tr(),
                    onTap: notifier.pickFromCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'ocr.pickGallery'.tr(),
                    onTap: notifier.pickFromGallery,
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

            // Preview image
            if (state.previewPath != null) ...[
              Text(
                'ocr.preview'.tr(),
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(state.previewPath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (state.previewPath != null) const SizedBox(height: 16),

            // Loading shimmer
            if (state.isLoading) ...[
              const _ShimmerBox(height: 18),
              const SizedBox(height: 12),
              const _ShimmerBox(height: 18),
              const SizedBox(height: 12),
              const _ShimmerBox(height: 18),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'ocr.scanning'.tr(),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ] else if (state.parsed != null) ...[
              // Parsed result fields
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
                onPressed: () => Navigator.of(context).pop(state.parsed),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('ocr.useResult'.tr()),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
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

class _ShimmerBox extends StatefulWidget {
  final double height;

  const _ShimmerBox({required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final highlight = theme.colorScheme.onSurface.withValues(alpha: 0.2);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = _controller.value;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (v - 0.3).clamp(0.0, 1.0),
                v.clamp(0.0, 1.0),
                (v + 0.3).clamp(0.0, 1.0),
              ],
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
