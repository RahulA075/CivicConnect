import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../features/issues/domain/entities/issue_entity.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../widgets/issue_card.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarkNotifierProvider);
    final feedItems  = ref.watch(feedNotifierProvider).valueOrNull
        ?? <IssueEntity>[];
    final myItems    = ref.watch(myIssuesNotifierProvider).valueOrNull
        ?? <IssueEntity>[];

    // Merge, deduplicate, keep only bookmarked
    final seen      = <String>{};
    final bookmarked = <IssueEntity>[
      ...feedItems,
      ...myItems,
    ].where((i) => bookmarkedIds.contains(i.id) && seen.add(i.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarked.isEmpty
          ? const EmptyState(
              icon:     Icons.bookmark_border_rounded,
              title:    'No bookmarks',
              subtitle: 'Bookmark issues to track them here.',
            )
          : ListView.builder(
              padding:    const EdgeInsets.symmetric(vertical: 8),
              itemCount:  bookmarked.length,
              itemBuilder: (_, i) => IssueCard(
                issue:        bookmarked[i],
                onTap:        () => context.push(
                    Routes.issueDetailPath(bookmarked[i].id)),
                isBookmarked: true,
                onBookmark:   () => ref
                    .read(bookmarkNotifierProvider.notifier)
                    .toggle(bookmarked[i].id),
              ),
            ),
    );
  }
}
