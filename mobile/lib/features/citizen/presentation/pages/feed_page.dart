import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../features/issues/presentation/providers/issues_provider.dart' show FeedFilter;
import '../../../../../features/issues/domain/entities/issue_entity.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/loading_indicator.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/issue_card.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _searchCtrl   = TextEditingController();
  final _scrollCtrl   = ScrollController();
  bool  _showSearch   = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(feedNotifierProvider.notifier).load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);
    final notifier  = ref.read(feedNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus:  true,
                decoration: const InputDecoration(
                  hintText: 'Search issues…',
                  border: InputBorder.none,
                ),
                onChanged: (q) => notifier.applyFilter(
                    notifier.filter.copyWith(search: q.isEmpty ? null : q)),
              )
            : const Text('Issue Feed'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                notifier.applyFilter(notifier.filter.copyWith(search: null));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, notifier),
          ),
        ],
      ),
      body: feedState.when(
        loading: () => const LoadingIndicator(),
        error:   (e, _) => ErrorView(
          message: e is Exception ? e.toString() : 'Failed to load feed',
          onRetry: () => notifier.refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon:        Icons.dynamic_feed_outlined,
              title:       'No issues yet',
              subtitle:    'Be the first to report a civic issue in your area.',
              actionLabel: 'Report Issue',
              onAction:    () => context.push(Routes.reportIssue),
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.builder(
              controller:   _scrollCtrl,
              padding:      const EdgeInsets.symmetric(vertical: 8),
              itemCount:    items.length + 1,
              itemBuilder:  (ctx, i) {
                if (i == items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child:   Center(child: CircularProgressIndicator()),
                  );
                }
                return IssueCard(
                  issue:     items[i],
                  onTap:     () => context.push(
                    Routes.issueDetailPath(items[i].id)),
                  onUpvote:  () => _upvote(items[i]),
                  onBookmark:() => ref
                      .read(bookmarkNotifierProvider.notifier)
                      .toggle(items[i].id),
                  isBookmarked: ref
                      .watch(bookmarkNotifierProvider)
                      .contains(items[i].id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _upvote(IssueEntity issue) async {
    ref.read(feedNotifierProvider.notifier).optimisticUpvote(issue.id);
    await ref.read(upvoteNotifierProvider.notifier).upvote(issue.id);
  }

  void _showFilterSheet(BuildContext ctx, notifier) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => FilterSheet(
        current: notifier.filter,
        onApply: (f) {
          notifier.applyFilter(f);
          Navigator.pop(ctx);
        },
        onClear: () {
          notifier.applyFilter(const FeedFilter());
          Navigator.pop(ctx);
        },
      ),
    );
  }
}
