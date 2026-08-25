import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SmartInputBar extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onMicTap;

  /// When `true` the bar renders a frosted-glass backdrop behind it,
  /// similar to Pennywise's blur-haze smart input area.
  final bool useBlur;

  const SmartInputBar({
    super.key,
    required this.onTap,
    this.onCameraTap,
    this.onMicTap,
    this.useBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bar = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.78)
            : colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.75,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: isDark ? 0.22 : 0.06),
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
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'input.placeholder'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                color: colorScheme.primary,
              ),
              onPressed: onCameraTap,
            ),
          if (onMicTap != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.mic_none_rounded,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              onPressed: onMicTap,
            ),
        ],
      ),
    );

    if (!useBlur) {
      return GestureDetector(onTap: onTap, child: bar);
    }

    // Wrap in ClipRRect + BackdropFilter for the frosted-glass effect.
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: GestureDetector(onTap: onTap, child: bar),
      ),
    );
  }
}
