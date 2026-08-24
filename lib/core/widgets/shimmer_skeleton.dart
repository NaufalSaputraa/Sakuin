import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable shimmer skeleton placeholder shown while data loads.
///
/// Use the static helpers for common patterns:
/// ```dart
/// ShimmerSkeleton.card(height: 110)       // wallet carousel placeholder
/// ShimmerSkeleton.tile()                  // transaction list item
/// ShimmerSkeleton.block(height: 180)      // chart / large block
/// ```
class ShimmerSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.margin,
  });

  // -- Composite presets ------------------------------------------------

  /// Wallet carousel card placeholder (150 x 110).
  static Widget walletCard({EdgeInsetsGeometry? margin}) {
    return ShimmerSkeleton(
      width: 150,
      height: 110,
      borderRadius: 18,
      margin: margin,
    );
  }

  /// Transaction list tile placeholder.
  static Widget tile({EdgeInsetsGeometry? margin}) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: const Row(
        children: [
          ShimmerSkeleton(width: 40, height: 40, borderRadius: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerSkeleton(width: double.infinity, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                ShimmerSkeleton(width: 120, height: 10, borderRadius: 6),
              ],
            ),
          ),
          SizedBox(width: 12),
          ShimmerSkeleton(width: 72, height: 14, borderRadius: 6),
        ],
      ),
    );
  }

  /// Budget progress placeholder (full width, matching BudgetProgressWidget layout).
  static Widget budgetProgress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: const Row(
        children: [
          ShimmerSkeleton(width: 78, height: 78, borderRadius: 39),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerSkeleton(width: 100, height: 14, borderRadius: 6),
                    ShimmerSkeleton(width: 64, height: 22, borderRadius: 8),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerSkeleton(width: 160, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                ShimmerSkeleton(width: 90, height: 10, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Analytics / chart block placeholder.
  static Widget chartBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        children: [
          const ShimmerSkeleton(width: double.infinity, height: 180, borderRadius: 12),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ShimmerSkeleton(width: 28, height: 14, borderRadius: 6),
                  SizedBox(width: 8),
                  ShimmerSkeleton(width: 100, height: 14, borderRadius: 6),
                  Spacer(),
                  ShimmerSkeleton(width: 72, height: 14, borderRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Category list row placeholder.
  static Widget categoryRow({EdgeInsetsGeometry? margin}) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: const Row(
        children: [
          ShimmerSkeleton(width: 40, height: 40, borderRadius: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerSkeleton(width: 120, height: 14, borderRadius: 6),
                SizedBox(height: 4),
                ShimmerSkeleton(width: 80, height: 10, borderRadius: 6),
              ],
            ),
          ),
          ShimmerSkeleton(width: 36, height: 36, borderRadius: 18),
        ],
      ),
    );
  }

  /// Chat message bubble placeholder (alternating widths).
  static Widget chatBubble({required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: ShimmerSkeleton(
          width: 220,
          height: 48,
          borderRadius: 16,
        ),
      ),
    );
  }

  // -- Base widget ------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .shimmer(
          duration: const Duration(milliseconds: 1200),
          color: highlightColor,
        );
  }
}

/// A full-screen loading placeholder that replaces [CircularProgressIndicator].
///
/// Renders a column of skeleton blocks that match the target section's shape.
class ShimmerLoadingSection extends StatelessWidget {
  /// Which section shape to render.
  final ShimmerSection section;

  const ShimmerLoadingSection({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      ShimmerSection.walletCarousel => SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => ShimmerSkeleton.walletCard(),
          ),
        ),
      ShimmerSection.budgetProgress => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerSkeleton.budgetProgress(),
        ),
      ShimmerSection.analyticsChart => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerSkeleton.chartBlock(),
        ),
      ShimmerSection.categoriesList => Column(
          children: List.generate(
            5,
            (_) => ShimmerSkeleton.categoryRow(),
          ),
        ),
      ShimmerSection.recentTransactions => Column(
          children: List.generate(
            4,
            (_) => ShimmerSkeleton.tile(),
          ),
        ),
      ShimmerSection.chatMessages => Column(
          children: List.generate(
            4,
            (i) => ShimmerSkeleton.chatBubble(isMe: i % 2 == 1),
          ),
        ),
    };
  }
}

enum ShimmerSection {
  walletCarousel,
  budgetProgress,
  analyticsChart,
  categoriesList,
  recentTransactions,
  chatMessages,
}
