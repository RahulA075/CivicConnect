import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/ai_analysis.dart';

/// Card shown on the issue detail screen with the AI-generated summary,
/// image labels, and stored analysis. Officers see this for quick triage.
class IssueAiSummaryCard extends ConsumerWidget {
  final String issueId;

  const IssueAiSummaryCard({super.key, required this.issueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnalysis = ref.watch(issueAnalysisProvider(issueId));
    final theme = Theme.of(context);

    return asyncAnalysis.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final analysis = data as AiAnalysis;
        return _AnalysisCard(analysis: analysis, theme: theme);
      },
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final AiAnalysis analysis;
  final ThemeData theme;

  const _AnalysisCard({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasSomething = analysis.complaintSummary != null ||
        analysis.imageLabels.isNotEmpty ||
        analysis.smartSuggestions.isNotEmpty;

    if (!hasSomething) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'AI Analysis',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (analysis.modelUsed != null)
                  Text(
                    analysis.modelUsed!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),

            // Complaint summary
            if (analysis.complaintSummary != null) ...[
              Text(
                'Summary',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                analysis.complaintSummary!,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
            ],

            // Severity reasoning
            if (analysis.severityReasoning != null) ...[
              _InfoRow(
                icon: Icons.flag_outlined,
                label: 'Severity',
                value:
                    '${analysis.suggestedPriority ?? 'Unknown'} — ${analysis.severityReasoning}',
              ),
              const SizedBox(height: 8),
            ],

            // Image labels
            if (analysis.imageLabels.isNotEmpty) ...[
              Text(
                'Image Classification',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: analysis.imageLabels
                    .take(5)
                    .map((l) => _LabelChip(label: l))
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Spam / duplicate flags
            if (analysis.spamFlagged)
              _FlagRow(
                icon: Icons.block_outlined,
                label: 'Spam flagged',
                subtitle: analysis.spamReason,
                color: theme.colorScheme.error,
              ),
            if (analysis.potentialDuplicate)
              _FlagRow(
                icon: Icons.content_copy_outlined,
                label: 'Potential duplicate',
                subtitle: analysis.duplicateOfTrackingId != null
                    ? 'Similar to ${analysis.duplicateOfTrackingId}'
                    : null,
                color: theme.colorScheme.tertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall,
              children: [
                TextSpan(
                    text: '$label: ',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  final ImageLabel label;
  const _LabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = '${(label.confidence * 100).round()}%';
    return Chip(
      label: Text('${label.label} $pct'),
      labelStyle: theme.textTheme.labelSmall,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      backgroundColor:
          theme.colorScheme.primaryContainer.withOpacity(0.5),
    );
  }
}

class _FlagRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;

  const _FlagRow(
      {required this.icon,
      required this.label,
      this.subtitle,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: color.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
