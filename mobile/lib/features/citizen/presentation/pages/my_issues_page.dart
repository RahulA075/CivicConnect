import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/loading_indicator.dart';
import '../widgets/issue_card.dart';

class MyIssuesPage extends ConsumerWidget {
  const MyIssuesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(myIssuesNotifierProvider);
    final notifier = ref.read(myIssuesNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: state.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Failed to load your issues',
          onRetry: notifier.refresh,
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon:        Icons.report_gmailerrorred_outlined,
              title:       'No reports yet',
              subtitle:    'Issues you report will appear here.',
              actionLabel: 'Report an Issue',
              onAction:    () => context.push(Routes.reportIssue),
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.builder(
              padding:    const EdgeInsets.symmetric(vertical: 8),
              itemCount:  items.length,
              itemBuilder: (_, i) => IssueCard(
                issue: items[i],
                onTap: () =>
                    context.push(Routes.issueDetailPath(items[i].id)),
                isBookmarked: ref
                    .watch(bookmarkNotifierProvider)
                    .contains(items[i].id),
                onBookmark: () => ref
                    .read(bookmarkNotifierProvider.notifier)
                    .toggle(items[i].id),
              ),
            ),
          );
        },
      ),
    );
  }
}
