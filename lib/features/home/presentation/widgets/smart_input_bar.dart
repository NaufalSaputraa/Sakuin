import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SmartInputBar extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onMicTap;

  const SmartInputBar({
    super.key,
    required this.onTap,
    this.onCameraTap,
    this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'input.placeholder'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onCameraTap != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.document_scanner_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                onPressed: onCameraTap,
              ),
            if (onMicTap != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.mic_none_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                onPressed: onMicTap,
              ),
          ],
        ),
      ),
    );
  }
}
