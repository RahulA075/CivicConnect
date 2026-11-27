import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../features/issues/domain/entities/issue_entity.dart';
import '../../domain/entities/analytics_entity.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';
import '../../domain/usecases/get_department_issues_usecase.dart';
import '../../domain/usecases/get_issue_trend_usecase.dart';
import '../../domain/usecases/officer_issue_actions_usecase.dart';

// ── Shared action state ───────────────────────────────────────────────────────

sealed class OfficerActionState { const OfficerActionState(); }
final class OfficerActionIdle    extends OfficerActionState { const OfficerActionIdle(); }
final class OfficerActionLoading extends OfficerActionState { const OfficerActionLoading(); }
final class OfficerActionSuccess extends OfficerActionState {
  const OfficerActionSuccess([this.issue]);
  final IssueEntity? issue;
}
final class OfficerActionFailure extends OfficerActionState {
  const OfficerActionFailure(this.failure);
  final Failure failure;
}

// ── Department issue queue notifier ──────────────────────────────────────────

class DeptIssuesNotifier
    extends StateNotifier<AsyncValue<List<IssueEntity>>> {
  DeptIssuesNotifier(this._useCase) : super(const AsyncValue.loading());

  final GetDepartmentIssuesUseCase _useCase;
  String? _departmentId;
  String? _statusFilter;

  Future<void> load({
    required String departmentId,
    String? status,
    bool refresh = false,
  }) async {
    _departmentId  = departmentId;
    _statusFilter  = status;
    if (refresh) state = const AsyncValue.loading();
    final result = await _useCase(
        departmentId: departmentId, status: status);
    result.fold(
      (f) => state = AsyncValue.error(f, StackTrace.current),
      (issues) => state = AsyncValue.data(issues),
    );
  }

  Future<void> refresh() async {
    if (_departmentId == null) return;
    await load(
        departmentId: _departmentId!, status: _statusFilter, refresh: true);
  }

  void applyStatusFilter(String? status) {
    _statusFilter = status;
    if (_departmentId != null) {
      load(departmentId: _departmentId!, status: status, refresh: true);
    }
  }
}

// ── My tasks notifier (field worker) ─────────────────────────────────────────

class MyTasksNotifier
    extends StateNotifier<AsyncValue<List<IssueEntity>>> {
  MyTasksNotifier() : super(const AsyncValue.data([]));

  Future<void> load() async {
    // Field worker task loading — uses officerActionsUseCaseProvider
  }
}

// ── Officer actions notifier ──────────────────────────────────────────────────

class OfficerActionsNotifier extends StateNotifier<OfficerActionState> {
  OfficerActionsNotifier(this._actions) : super(const OfficerActionIdle());

  final OfficerIssueActionsUseCase _actions;

  Future<void> accept(String issueId) async {
    state = const OfficerActionLoading();
    final r = await _actions.accept(issueId);
    state = r.fold(
      (f) => OfficerActionFailure(f),
      (i) => OfficerActionSuccess(i),
    );
  }

  Future<void> reject(String issueId, String reason) async {
    state = const OfficerActionLoading();
    final r = await _actions.reject(issueId, reason);
    state = r.fold(
      (f) => OfficerActionFailure(f),
      (_) => const OfficerActionSuccess(),
    );
  }

  Future<void> assign(String issueId, String workerId, {String? note}) async {
    state = const OfficerActionLoading();
    final r = await _actions.assign(issueId, workerId, note: note);
    state = r.fold(
      (f) => OfficerActionFailure(f),
      (i) => OfficerActionSuccess(i),
    );
  }

  Future<void> updateStatus(String issueId, String status, {String? note}) async {
    state = const OfficerActionLoading();
    final r = await _actions.updateStatus(issueId, status, note: note);
    state = r.fold(
      (f) => OfficerActionFailure(f),
      (i) => OfficerActionSuccess(i),
    );
  }

  void reset() => state = const OfficerActionIdle();
}

// ── Timeline notifier ─────────────────────────────────────────────────────────

class TimelineNotifier
    extends StateNotifier<AsyncValue<List<StatusHistoryEntity>>> {
  TimelineNotifier(this._actions) : super(const AsyncValue.data([]));

  final OfficerIssueActionsUseCase _actions;

  Future<void> load(String issueId) async {
    state = const AsyncValue.loading();
    final r = await _actions.getHistory(issueId);
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      (h) => AsyncValue.data(h),
    );
  }
}

// ── Workers notifier ──────────────────────────────────────────────────────────

class WorkersNotifier
    extends StateNotifier<AsyncValue<List<WorkerEntity>>> {
  WorkersNotifier(this._actions) : super(const AsyncValue.data([]));

  final OfficerIssueActionsUseCase _actions;

  Future<void> load({
    required String departmentId,
    required String municipalityId,
  }) async {
    state = const AsyncValue.loading();
    final r = await _actions.getWorkers(
        departmentId: departmentId, municipalityId: municipalityId);
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      (w) => AsyncValue.data(w),
    );
  }
}

// ── Analytics notifier ────────────────────────────────────────────────────────

class AnalyticsNotifier extends StateNotifier<AsyncValue<DashboardSummaryEntity>> {
  AnalyticsNotifier(this._summary, this._trend)
      : super(const AsyncValue.loading());

  final GetDashboardSummaryUseCase _summary;
  final GetIssueTrendUseCase       _trend;

  List<TrendPointEntity> trendData = [];

  Future<void> load(String municipalityId, {String? departmentId}) async {
    state = const AsyncValue.loading();
    final r = await _summary(municipalityId);
    r.fold(
      (f) => state = AsyncValue.error(f, StackTrace.current),
      (s) => state = AsyncValue.data(s),
    );
    final tr = await _trend(
        municipalityId: municipalityId, days: 30, departmentId: departmentId);
    tr.fold((_) {}, (pts) => trendData = pts);
    // Trigger rebuild with same summary but updated trend
    if (state is AsyncData<DashboardSummaryEntity>) {
      state = AsyncValue.data((state as AsyncData<DashboardSummaryEntity>).value);
    }
  }
}
