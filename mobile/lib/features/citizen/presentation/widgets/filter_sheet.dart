import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../features/issues/presentation/providers/issues_provider.dart' show FeedFilter;

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({
    super.key,
    required this.current,
    required this.onApply,
    required this.onClear,
  });

  final FeedFilter              current;
  final ValueChanged<FeedFilter> onApply;
  final VoidCallback             onClear;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  String? _categoryId;
  String? _status;

  static const _statuses = [
    'SUBMITTED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED',
  ];

  @override
  void initState() {
    super.initState();
    _categoryId = widget.current.categoryId;
    _status     = widget.current.status;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesNotifierProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand:          false,
      initialChildSize: 0.6,
      maxChildSize:    0.9,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text('Filter Issues', style: theme.textTheme.titleLarge),
            const Gap(16),

            // ── Status ────────────────────────────────────────────
            Text('Status', style: theme.textTheme.labelLarge),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((s) {
                final selected = _status == s;
                return FilterChip(
                  label:    Text(s.replaceAll('_', ' ')),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _status = selected ? null : s),
                );
              }).toList(),
            ),
            const Gap(16),

            // ── Category ──────────────────────────────────────────
            Text('Category', style: theme.textTheme.labelLarge),
            const Gap(8),
            categoriesState.when(
              loading: () => const LinearProgressIndicator(),
              error:   (_, __) => const SizedBox.shrink(),
              data: (cats) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((c) {
                  final id       = c['id'] as String;
                  final name     = c['name'] as String? ?? '';
                  final selected = _categoryId == id;
                  return FilterChip(
                    label:    Text(name),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _categoryId = selected ? null : id),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClear,
                  child:     const Text('Clear All'),
                ),
              ),
              const Gap(12),
              Expanded(
                child: FilledButton(
                  onPressed: () => widget.onApply(FeedFilter(
                    categoryId: _categoryId,
                    status:     _status,
                  )),
                  child: const Text('Apply'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
