import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/duplicate_candidate.dart';

/// Warning card shown when AI finds existing issues similar to the one
/// being submitted. Shows the top candidates so the citizen can upvote
/// instead of creating a duplicate.
class DuplicateWarningCard extends ConsumerWidget {
  /// Called when the citizen taps on a candidate — navigate to that issue.
  final void Function(DuplicateCandidate candidate)? onViewCandidate;
  final VoidCallback? onDismiss;

  const DuplicateWarningCard({
    super.key,
    this.onViewCandidate,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAnalysisNotifierProvider);

    if (state.isCheckingDuplicate) {
      return _CheckingIndicator();
    }

    if (!state.hasDuplicateWarning) return const SizedBox.shrink();

    final candidates = state.duplicateResult!.candidates;
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: theme.colorScheme.tertiary.withOpacity(0.4)),
        ),
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.content_copy_outlined,
                      color: theme.colorScheme.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Similar issue${candidates.length > 1 ? 's' : ''} already reported',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onDismiss ??
                        () => ref
                            .read(aiAnalysisNotifierProvider.notifier)
                            .dismissDuplicateWarning(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Consider upvoting an existing report instead of creating a new one.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 10),

              // Top 3 candidates
              ...candidates.take(3).map(
                    (c) => _CandidateTile(
                      candidate: c,
                      onTap: () => onViewCandidate?.call(c),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Checking for duplicate reports…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final DuplicateCandidate candidate;
  final VoidCallback onTap;

  const _CandidateTile({required this.candidate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dist = candidate.distanceMetres < 1000
        ? '${candidate.distanceMetres.round()} m'
        : '${(candidate.distanceMetres / 1000).toStringAsFixed(1)} km';
    final pct = '${(candidate.similarityScore * 100).round()}% match';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.title,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${candidate.trackingId} · $dist away · $pct',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(candidate.status),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(status, theme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return theme.colorScheme.primary;
      case 'IN_PROGRESS':
      case 'ASSIGNED':
        return Colors.orange;
      case 'RESOLVED':
      case 'VERIFIED':
        return Colors.green;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
