import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../features/issues/domain/entities/issue_entity.dart';
import '../widgets/issue_card.dart';

final _trackResultProvider =
    StateProvider<AsyncValue<IssueEntity?>>((ref) => const AsyncValue.data(null));

class TrackComplaintPage extends ConsumerStatefulWidget {
  const TrackComplaintPage({super.key, this.prefillId});
  final String? prefillId;

  @override
  ConsumerState<TrackComplaintPage> createState() =>
      _TrackComplaintPageState();
}

class _TrackComplaintPageState extends ConsumerState<TrackComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefillId != null) {
      _idCtrl.text = widget.prefillId!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _track());
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(_trackResultProvider.notifier).state =
        const AsyncValue.loading();

    final result = await ref
        .read(issueRepositoryProvider)
        .trackIssue(_idCtrl.text.trim().toUpperCase());

    result.fold(
      (failure) => ref.read(_trackResultProvider.notifier).state =
          AsyncValue.error(failure, StackTrace.current),
      (issue) => ref.read(_trackResultProvider.notifier).state =
          AsyncValue.data(issue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(_trackResultProvider);
    final theme  = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Track Complaint')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.onPrimaryContainer),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Enter your complaint tracking ID (e.g. CC-2026-00123) '
                      'to see the latest status.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ]),
              ),
              const Gap(20),

              // ── Input ────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Row(children: [
                  Expanded(
                    child: AppTextField(
                      controller:      _idCtrl,
                      label:           'Tracking ID',
                      hint:            'CC-2026-XXXXX',
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.receipt_long_outlined),
                      validator: (v) =>
                          Validators.required(v, label: 'Tracking ID'),
                      onSubmitted: (_) => _track(),
                    ),
                  ),
                  const Gap(8),
                  FilledButton(
                    onPressed: _track,
                    child:     const Text('Track'),
                  ),
                ]),
              ),
              const Gap(24),

              // ── Result ────────────────────────────────────────────
              Expanded(
                child: result.when(
                  data: (issue) {
                    if (issue == null) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.search_rounded,
                              size: 64,
                              color: theme.colorScheme.outline),
                          const Gap(12),
                          Text('Enter a tracking ID above',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ]),
                      );
                    }
                    return IssueCard(issue: issue, onTap: () {});
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.error_outline,
                          size: 48, color: theme.colorScheme.error),
                      const Gap(8),
                      Text('Issue not found',
                          style: theme.textTheme.titleMedium),
                      const Gap(4),
                      Text('Check the tracking ID and try again.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
