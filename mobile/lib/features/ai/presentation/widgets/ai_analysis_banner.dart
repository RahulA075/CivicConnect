import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';

/// Compact banner shown on the issue submission form after AI analysis completes.
/// Shows category suggestion, priority suggestion, and smart tips in one card.
class AiAnalysisBanner extends ConsumerWidget {
  final VoidCallback? onAcceptCategory;
  final VoidCallback? onAcceptPriority;

  const AiAnalysisBanner({
    super.key,
    this.onAcceptCategory,
    this.onAcceptPriority,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAnalysisNotifierProvider);
    final theme = Theme.of(context);

    if (state.isAnalyzing) {
      return _LoadingBanner(theme: theme);
    }

    final analysis = state.analysis;
    if (analysis == null) return const SizedBox.shrink();

    final hasAnything = state.hasCategorySuggestion ||
        state.hasPrioritySuggestion ||
        state.smartSuggestions.isNotEmpty ||
        state.hasImageLabels;

    if (!hasAnything) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('AI Suggestions',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      )),
                ],
              ),
              const SizedBox(height: 10),

              // Category suggestion
              if (state.hasCategorySuggestion) ...[
                _SuggestionRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: analysis.suggestedCategoryName!,
                  confidence: analysis.categoryConfidence,
                  actionLabel: 'Apply',
                  onAction: onAcceptCategory,
                ),
                const SizedBox(height: 8),
              ],

              // Priority suggestion
              if (state.hasPrioritySuggestion) ...[
                _SuggestionRow(
                  icon: Icons.flag_outlined,
                  label: 'Priority',
                  value: analysis.suggestedPriority!,
                  confidence: analysis.severityConfidence,
                  subText: analysis.severityReasoning,
                  actionLabel: 'Apply',
                  onAction: onAcceptPriority,
                ),
                const SizedBox(height: 8),
              ],

              // Image labels
              if (state.hasImageLabels) ...[
                _ImageLabelsRow(analysis.imageLabels
                    .take(3)
                    .map((l) => l.label)
                    .toList()),
                const SizedBox(height: 8),
              ],

              // Smart suggestions
              if (state.smartSuggestions.isNotEmpty) ...[
                const Divider(height: 16),
                ...state.smartSuggestions.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(tip,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBanner extends StatelessWidget {
  final ThemeData theme;
  const _LoadingBanner({required this.theme});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 0,
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text('AI is analysing your report…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      );
}

class _SuggestionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? confidence;
  final String? subText;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SuggestionRow({
    required this.icon,
    required this.label,
    required this.value,
    this.confidence,
    this.subText,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = confidence != null ? '${(confidence! * 100).round()}%' : '';

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('$label: ',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Flexible(
                    child: Text(value,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (pct.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(pct,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green.shade700)),
                  ],
                ],
              ),
              if (subText != null)
                Text(subText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11)),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _ImageLabelsRow extends StatelessWidget {
  final List<String> labels;
  const _ImageLabelsRow(this.labels);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Text('Image: ',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ...labels.map((l) => Chip(
              label: Text(l),
              labelStyle: theme.textTheme.labelSmall,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              backgroundColor:
                  theme.colorScheme.primaryContainer.withOpacity(0.5),
            )),
      ],
    );
  }
}
