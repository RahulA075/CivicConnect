import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/usecases/get_public_feed_usecase.dart';
import '../../domain/usecases/get_my_issues_usecase.dart';
import '../../domain/usecases/report_issue_usecase.dart';
import '../../domain/usecases/upvote_issue_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _getMunicipalityId() =>
    LocalStorage.getAuthString(StorageKeys.municipalityId) ?? '';

// ── Feed filters state ────────────────────────────────────────────────────────

class FeedFilter {
  const FeedFilter({this.categoryId, this.status, this.search});
  final String? categoryId;
  final String? status;
  final String? search;

  FeedFilter copyWith({
    String? categoryId,
    String? status,
    String? search,
  }) =>
      FeedFilter(
        categoryId: categoryId ?? this.categoryId,
        status:     status     ?? this.status,
        search:     search     ?? this.search,
      );

  FeedFilter clear() => const FeedFilter();
}

// ── Feed notifier ─────────────────────────────────────────────────────────────

class FeedNotifier
    extends StateNotifier<AsyncValue<List<IssueEntity>>> {
  FeedNotifier(this._useCase)
      : super(const AsyncValue.loading()) {
    load();
  }

  final GetPublicFeedUseCase _useCase;
  FeedFilter _filter = const FeedFilter();
  int _page          = 0;
  bool _hasMore      = true;
  final List<IssueEntity> _items = [];

  FeedFilter get filter => _filter;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _page    = 0;
      _hasMore = true;
      _items.clear();
      state = const AsyncValue.loading();
    }
    if (!_hasMore) return;

    final municipalityId = _getMunicipalityId();
    final result = await _useCase(
      municipalityId: municipalityId,
      page:           _page,
      categoryId:     _filter.categoryId,
      status:         _filter.status,
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (newItems) {
        var filtered = newItems;
        if (_filter.search != null && _filter.search!.isNotEmpty) {
          final q = _filter.search!.toLowerCase();
          filtered = filtered
              .where((i) =>
                  i.title.toLowerCase().contains(q) ||
                  i.description.toLowerCase().contains(q) ||
                  i.address.toLowerCase().contains(q))
              .toList();
        }
        _items.addAll(filtered);
        _hasMore = newItems.isNotEmpty;
        _page++;
        state = AsyncValue.data(List.unmodifiable(_items));
      },
    );
  }

  Future<void> applyFilter(FeedFilter filter) async {
    _filter = filter;
    await load(refresh: true);
  }

  Future<void> refresh() => load(refresh: true);

  void optimisticUpvote(String issueId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.map((i) {
        if (i.id != issueId) return i;
        return IssueEntity(
          id: i.id, trackingId: i.trackingId, title: i.title,
          description: i.description, status: i.status, priority: i.priority,
          categoryName: i.categoryName, categoryId: i.categoryId,
          categoryColor: i.categoryColor, latitude: i.latitude,
          longitude: i.longitude, address: i.address,
          upvoteCount: i.upvoteCount + 1, commentCount: i.commentCount,
          createdAt: i.createdAt, reporterName: i.reporterName,
          assignedTo: i.assignedTo, departmentName: i.departmentName,
          municipalityName: i.municipalityName, imageUrls: i.imageUrls,
          resolvedAt: i.resolvedAt, dueDate: i.dueDate,
          isUpvotedByMe: true, isOverdue: i.isOverdue,
        );
      }).toList(),
    );
  }
}

// ── My issues notifier ────────────────────────────────────────────────────────

class MyIssuesNotifier
    extends StateNotifier<AsyncValue<List<IssueEntity>>> {
  MyIssuesNotifier(this._useCase)
      : super(const AsyncValue.loading()) {
    load();
  }

  final GetMyIssuesUseCase _useCase;
  int _page     = 0;
  bool _hasMore = true;
  final List<IssueEntity> _items = [];

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _page    = 0;
      _hasMore = true;
      _items.clear();
      state = const AsyncValue.loading();
    }
    if (!_hasMore) return;

    final result = await _useCase(page: _page);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (newItems) {
        _items.addAll(newItems);
        _hasMore = newItems.isNotEmpty;
        _page++;
        state = AsyncValue.data(List.unmodifiable(_items));
      },
    );
  }

  Future<void> refresh() => load(refresh: true);
}

// ── Report issue ──────────────────────────────────────────────────────────────

sealed class ReportIssueState { const ReportIssueState(); }
final class ReportIssueIdle    extends ReportIssueState { const ReportIssueIdle(); }
final class ReportIssueLoading extends ReportIssueState { const ReportIssueLoading(); }
final class ReportIssueSuccess extends ReportIssueState {
  const ReportIssueSuccess(this.issue);
  final IssueEntity issue;
}
final class ReportIssueFailure extends ReportIssueState {
  const ReportIssueFailure(this.failure);
  final Failure failure;
}

class ReportIssueNotifier extends StateNotifier<ReportIssueState> {
  ReportIssueNotifier(this._useCase) : super(const ReportIssueIdle());
  final ReportIssueUseCase _useCase;

  Future<void> submit({
    required String title,
    required String description,
    required String categoryId,
    required double latitude,
    required double longitude,
    required String address,
    String? priority,
    bool anonymous = false,
    List<File> images = const [],
  }) async {
    state = const ReportIssueLoading();
    final result = await _useCase(
      title: title, description: description, categoryId: categoryId,
      latitude: latitude, longitude: longitude, address: address,
      priority: priority, anonymous: anonymous, images: images,
    );
    result.fold(
      (f) => state = ReportIssueFailure(f),
      (i) => state = ReportIssueSuccess(i),
    );
  }

  void reset() => state = const ReportIssueIdle();
}

// ── Upvote notifier ───────────────────────────────────────────────────────────

class UpvoteNotifier extends StateNotifier<AsyncValue<void>> {
  UpvoteNotifier(this._useCase) : super(const AsyncValue.data(null));
  final UpvoteIssueUseCase _useCase;

  Future<IssueEntity?> upvote(String issueId) async {
    state = const AsyncValue.loading();
    final result = await _useCase(issueId);
    return result.fold(
      (f) { state = AsyncValue.error(f, StackTrace.current); return null; },
      (issue) { state = const AsyncValue.data(null); return issue; },
    );
  }
}

// ── Bookmarks (local) ─────────────────────────────────────────────────────────

class BookmarkNotifier extends StateNotifier<Set<String>> {
  BookmarkNotifier() : super({}) {
    _load();
  }

  static const _key = 'bookmarked_issues';

  void _load() {
    final raw = LocalStorage.getString(_key) ?? '';
    if (raw.isNotEmpty) state = raw.split(',').toSet();
  }

  void toggle(String issueId) {
    final next = Set<String>.from(state);
    if (next.contains(issueId)) {
      next.remove(issueId);
    } else {
      next.add(issueId);
    }
    state = next;
    LocalStorage.setString(_key, next.join(','));
  }

  bool isBookmarked(String issueId) => state.contains(issueId);
}

// ── Categories notifier ───────────────────────────────────────────────────────

class CategoriesNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  CategoriesNotifier(this._useCase)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final GetCategoriesUseCase _useCase;

  Future<void> _load() async {
    final id = _getMunicipalityId();
    if (id.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    final result = await _useCase(id);
    result.fold(
      (f) => state = AsyncValue.error(f, StackTrace.current),
      (cats) => state = AsyncValue.data(cats),
    );
  }
}
