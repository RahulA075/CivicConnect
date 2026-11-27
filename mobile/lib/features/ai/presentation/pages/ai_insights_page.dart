import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/ai_analysis.dart';

/// Full-page AI insights screen for a specific issue.
/// Accessible from issue detail via "View AI Analysis" button.
class AiInsightsPage extends ConsumerWidget {
  final String issueId;
  final String trackingId;

  const AiInsightsPage({
    super.key,
    required this.issueId,
    required this.trackingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnalysis = ref.watch(issueAnalysisProvider(issueId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Analysis · $trackingId'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Re-analyse',
            onPressed: () => ref.invalidate(issueAnalysisProvider(issueId)),
          ),
        ],
      ),
      body: asyncAnalysis.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Could not load AI analysis',
          onRetry: () => ref.invalidate(issueAnalysisProvider(issueId)),
        ),
        data: (data) {
          if (data == null) {
            return _NoAnalysis(issueId: issueId);
          }
          final analysis = data as AiAnalysis;
          return _AnalysisBody(analysis: analysis, theme: theme);
        },
      ),
    );
  }
}

class _NoAnalysis extends ConsumerWidget {
  final String issueId;
  const _NoAnalysis({required this.issueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 56, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No AI analysis yet',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Analysis runs automatically in the background after submission.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Check again'),
              onPressed: () => ref.invalidate(issueAnalysisProvider(issueId)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisBody extends StatelessWidget {
  final AiAnalysis analysis;
  final ThemeData theme;
  const _AnalysisBody({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary ───────────────────────────────────────────────────
        if (analysis.complaintSummary != null) ...[
          _SectionHeader('Complaint Summary'),
          const SizedBox(height: 6),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(analysis.complaintSummary!,
                  style: theme.textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Category & Priority ──────────────────────────────────────
        _SectionHeader('Suggestions'),
        const SizedBox(height: 6),
        _SuggestionGrid(analysis: analysis, theme: theme),
        const SizedBox(height: 16),

        // ── Image Classification ─────────────────────────────────────
        if (analysis.imageLabels.isNotEmpty) ...[
          _SectionHeader('Image Classification'),
          const SizedBox(height: 6),
          _ImageLabelsSection(analysis.imageLabels, theme),
          const SizedBox(height: 16),
        ],

        // ── Flags ────────────────────────────────────────────────────
        if (analysis.spamFlagged || analysis.potentialDuplicate) ...[
          _SectionHeader('Flags'),
          const SizedBox(height: 6),
          if (analysis.spamFlagged)
            _FlagTile(
              icon: Icons.block_outlined,
              title: 'Spam Detected',
              subtitle: analysis.spamReason ??
                  'Content may be irrelevant or abusive.',
              confidence: analysis.spamConfidence,
              color: theme.colorScheme.error,
            ),
          if (analysis.potentialDuplicate) ...[
            if (analysis.spamFlagged) const SizedBox(height: 8),
            _FlagTile(
              icon: Icons.content_copy_outlined,
              title: 'Potential Duplicate',
              subtitle: analysis.duplicateOfTrackingId != null
                  ? 'Similar to issue ${analysis.duplicateOfTrackingId}  '
                      '(${((analysis.duplicateSimilarity ?? 0) * 100).round()}% match)'
                  : 'A similar issue may already exist nearby.',
              color: theme.colorScheme.tertiary,
            ),
          ],
          const SizedBox(height: 16),
        ],

        // ── Smart Suggestions ────────────────────────────────────────
        if (analysis.smartSuggestions.isNotEmpty) ...[
          _SectionHeader('Smart Tips'),
          const SizedBox(height: 6),
          ...analysis.smartSuggestions.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            theme.colorScheme.primaryContainer,
                        child: Text('${e.key + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(e.value,
                              style: theme.textTheme.bodySmall)),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 16),
        ],

        // ── Meta ─────────────────────────────────────────────────────
        if (analysis.modelUsed != null) ...[
          const Divider(),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Model: ${analysis.modelUsed} · '
                '${analysis.analysisDurationMs}ms',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700),
      );
}

class _SuggestionGrid extends StatelessWidget {
  final AiAnalysis analysis;
  final ThemeData theme;
  const _SuggestionGrid({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (analysis.hasCategorySuggestion)
          Expanded(
            child: _StatCard(
              icon: Icons.category_outlined,
              label: 'Category',
              value: analysis.suggestedCategoryName!,
              confidence: analysis.categoryConfidence,
              theme: theme,
            ),
          ),
        if (analysis.hasCategorySuggestion && analysis.hasPrioritySuggestion)
          const SizedBox(width: 8),
        if (analysis.hasPrioritySuggestion)
          Expanded(
            child: _StatCard(
              icon: Icons.flag_outlined,
              label: 'Priority',
              value: analysis.suggestedPriority!,
              confidence: analysis.severityConfidence,
              theme: theme,
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? confidence;
  final ThemeData theme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.confidence,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final pct = confidence != null
        ? '${(confidence! * 100).round()}% confident'
        : '';
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (pct.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(pct,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: Colors.green.shade700)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageLabelsSection extends StatelessWidget {
  final List<ImageLabel> labels;
  final ThemeData theme;
  const _ImageLabelsSection(this.labels, this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: labels
          .map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l.label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500)),
                  ),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: l.confidence,
                      backgroundColor:
                          theme.colorScheme.outlineVariant.withOpacity(0.3),
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(l.confidence * 100).round()}%',
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FlagTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double? confidence;
  final Color color;

  const _FlagTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.confidence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: color, fontWeight: FontWeight.w600)),
                    if (confidence != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${(confidence! * 100).round()}%',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: color.withOpacity(0.7)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
