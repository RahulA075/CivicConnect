import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';

/// Warning card shown when AI detects the submission looks like spam.
/// Citizen can dismiss and proceed anyway.
class SpamWarningCard extends ConsumerWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onProceedAnyway;

  const SpamWarningCard({
    super.key,
    this.onDismiss,
    this.onProceedAnyway,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAnalysisNotifierProvider);
    if (!state.hasSpamWarning) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final reason = state.analysis?.spamReason;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.4)),
        ),
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This may be flagged as spam',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (reason != null) ...[
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDismiss ??
                        () => ref
                            .read(aiAnalysisNotifierProvider.notifier)
                            .dismissSpamWarning(),
                    child: Text(
                      'Edit report',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onProceedAnyway,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: theme.colorScheme.error.withOpacity(0.6)),
                    ),
                    child: const Text('Submit anyway'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
