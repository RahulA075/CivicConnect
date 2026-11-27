import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';

// ── Unread badge count ─────────────────────────────────────────────────────────

class UnreadCountNotifier extends StateNotifier<int> {
  UnreadCountNotifier(this._useCase) : super(0) {
    refresh();
  }

  final GetUnreadCountUseCase _useCase;

  Future<void> refresh() async {
    final r = await _useCase();
    r.fold((_) {}, (count) => state = count);
  }

  void decrement() => state = (state - 1).clamp(0, 9999);
  void reset()     => state = 0;
}

// ── Inbox notifier ─────────────────────────────────────────────────────────────

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationEntity>>> {
  NotificationsNotifier({
    required GetNotificationsUseCase getNotifications,
    required MarkReadUseCase         markReadUC,
    required MarkAllReadUseCase      markAllReadUC,
  })  : _getNotifications = getNotifications,
        _markReadUC        = markReadUC,
        _markAllReadUC     = markAllReadUC,
        super(const AsyncValue.loading()) {
    load();
  }

  final GetNotificationsUseCase _getNotifications;
  final MarkReadUseCase         _markReadUC;
  final MarkAllReadUseCase      _markAllReadUC;

  int  _page    = 0;
  bool _hasMore = true;
  final List<NotificationEntity> _items = [];

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _page    = 0;
      _hasMore = true;
      _items.clear();
      state = const AsyncValue.loading();
    }
    if (!_hasMore) return;

    final result = await _getNotifications(page: _page);
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

  Future<void> markRead(String id) async {
    await _markReadUC(id);
    final updated = _items
        .map((n) => n.id == id ? _withRead(n, true) : n)
        .toList();
    _items
      ..clear()
      ..addAll(updated);
    state = AsyncValue.data(List.unmodifiable(_items));
  }

  Future<void> markAllRead() async {
    await _markAllReadUC();
    final updated = _items.map((n) => _withRead(n, true)).toList();
    _items
      ..clear()
      ..addAll(updated);
    state = AsyncValue.data(List.unmodifiable(_items));
  }

  NotificationEntity _withRead(NotificationEntity n, bool read) =>
      NotificationEntity(
        id:        n.id,
        title:     n.title,
        body:      n.body,
        eventType: n.eventType,
        channel:   n.channel,
        createdAt: n.createdAt,
        isRead:    read,
        issueId:   n.issueId,
        actionUrl: n.actionUrl,
        readAt:    read ? DateTime.now() : n.readAt,
      );
}

// ── Preferences notifier ───────────────────────────────────────────────────────

class NotificationPrefsNotifier
    extends StateNotifier<AsyncValue<NotificationPreferencesEntity>> {
  NotificationPrefsNotifier(this._get, this._update)
      : super(const AsyncValue.loading()) {
    load();
  }

  final GetNotificationPrefsUseCase    _get;
  final UpdateNotificationPrefsUseCase _update;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final r = await _get();
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<bool> update(NotificationPreferencesEntity prefs) async {
    final r = await _update(prefs);
    return r.fold((_) => false, (updated) {
      state = AsyncValue.data(updated);
      return true;
    });
  }
}
