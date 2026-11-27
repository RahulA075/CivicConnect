import 'package:flutter/material.dart';

/// Centered circular progress indicator for full-screen loading states.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox.square(
          dimension: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}

/// Shimmer placeholder for list items while loading.
class ShimmerTile extends StatelessWidget {
  const ShimmerTile({
    super.key,
    this.height = 80,
    this.borderRadius = 12,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
