import 'package:flutter/material.dart';

import 'package:todo_flutter_app/app/spacing.dart';

/// A shimmer-style loading placeholder for list items.
///
/// Shows [itemCount] rounded rectangles to indicate content is loading.
/// Uses the surface-variant color so it works in both light and dark themes.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({this.itemCount = 5, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Loading content',
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) =>
            _SkeletonItem(color: colorScheme.surfaceContainerHighest),
      ),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.xxl + AppSpacing.md,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
