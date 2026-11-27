import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/usecases/admin_usecases.dart';

// ── Generic action state ──────────────────────────────────────────────────────

sealed class AdminActionState { const AdminActionState(); }
final class AdminActionIdle    extends AdminActionState { const AdminActionIdle(); }
final class AdminActionLoading extends AdminActionState { const AdminActionLoading(); }
final class AdminActionSuccess extends AdminActionState { const AdminActionSuccess(); }
final class AdminActionFailure extends AdminActionState {
  const AdminActionFailure(this.failure);
  final Failure failure;
}

// ── Department notifier ───────────────────────────────────────────────────────

class DepartmentsNotifier
    extends StateNotifier<AsyncValue<List<DepartmentEntity>>> {
  DepartmentsNotifier(this._get, this._create, this._update, this._deactivate)
      : super(const AsyncValue.loading());

  final GetDepartmentsUseCase     _get;
  final CreateDepartmentUseCase   _create;
  final UpdateDepartmentUseCase   _update;
  final DeactivateDepartmentUseCase _deactivate;

  String? _municipalityId;

  Future<void> load(String municipalityId) async {
    _municipalityId = municipalityId;
    state = const AsyncValue.loading();
    final r = await _get(municipalityId);
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<bool> create(Map<String, dynamic> data) async {
    if (_municipalityId == null) return false;
    final r = await _create(_municipalityId!, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    final r = await _update(id, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }

  Future<bool> deactivate(String id) async {
    final r = await _deactivate(id);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }
}

// ── Category notifier ─────────────────────────────────────────────────────────

class CategoriesAdminNotifier
    extends StateNotifier<AsyncValue<List<CategoryEntity>>> {
  CategoriesAdminNotifier(this._get, this._create, this._update)
      : super(const AsyncValue.loading());

  final GetCategoriesAdminUseCase _get;
  final CreateCategoryUseCase     _create;
  final UpdateCategoryUseCase     _update;

  String? _municipalityId;

  Future<void> load(String municipalityId) async {
    _municipalityId = municipalityId;
    state = const AsyncValue.loading();
    final r = await _get(municipalityId);
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<bool> create(Map<String, dynamic> data) async {
    if (_municipalityId == null) return false;
    final r = await _create(_municipalityId!, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    final r = await _update(id, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }
}

// ── SLA Policy notifier ───────────────────────────────────────────────────────

class SlaPoliciesNotifier
    extends StateNotifier<AsyncValue<List<SlaPolicyEntity>>> {
  SlaPoliciesNotifier(this._get, this._create, this._update, this._deactivate)
      : super(const AsyncValue.loading());

  final GetSlaPoliciesUseCase   _get;
  final CreateSlaPolicyUseCase  _create;
  final UpdateSlaPolicyUseCase  _update;
  final Future<dynamic> Function(String) _deactivate;

  String? _municipalityId;

  Future<void> load(String municipalityId) async {
    _municipalityId = municipalityId;
    state = const AsyncValue.loading();
    final r = await _get(municipalityId);
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<bool> create(Map<String, dynamic> data) async {
    if (_municipalityId == null) return false;
    final r = await _create(_municipalityId!, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    final r = await _update(id, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }

  Future<bool> deactivate(String id) async {
    await _deactivate(id);
    load(_municipalityId!);
    return true;
  }
}

// ── Escalation rule notifier ──────────────────────────────────────────────────

class EscalationRulesNotifier
    extends StateNotifier<AsyncValue<List<EscalationRuleEntity>>> {
  EscalationRulesNotifier(this._get, this._create, this._update, this._deactivate)
      : super(const AsyncValue.loading());

  final GetEscalationRulesUseCase   _get;
  final CreateEscalationRuleUseCase _create;
  final UpdateEscalationRuleUseCase _update;
  final Future<dynamic> Function(String) _deactivate;

  String? _municipalityId;

  Future<void> load(String municipalityId) async {
    _municipalityId = municipalityId;
    state = const AsyncValue.loading();
    final r = await _get(municipalityId);
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<bool> create(Map<String, dynamic> data) async {
    if (_municipalityId == null) return false;
    final r = await _create(_municipalityId!, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    final r = await _update(id, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }

  Future<bool> deactivate(String id) async {
    await _deactivate(id);
    load(_municipalityId!);
    return true;
  }
}

// ── Admin users notifier ──────────────────────────────────────────────────────

class AdminUsersNotifier
    extends StateNotifier<AsyncValue<List<AdminUserEntity>>> {
  AdminUsersNotifier(this._get, this._invite, this._actions)
      : super(const AsyncValue.loading());

  final GetAdminUsersUseCase    _get;
  final InviteUserUseCase       _invite;
  final AdminUserActionsUseCase _actions;

  String? _municipalityId;

  Future<void> load(String municipalityId, {String? departmentId}) async {
    _municipalityId = municipalityId;
    state = const AsyncValue.loading();
    final r = await _get(municipalityId, departmentId: departmentId);
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<bool> invite(Map<String, dynamic> data) async {
    if (_municipalityId == null) return false;
    final r = await _invite(_municipalityId!, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }

  Future<bool> deactivate(String userId) async {
    final r = await _actions.deactivate(userId);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }

  Future<bool> reactivate(String userId) async {
    final r = await _actions.reactivate(userId);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }
}

// ── Emergency alerts notifier ─────────────────────────────────────────────────

class EmergencyAlertsNotifier
    extends StateNotifier<AsyncValue<List<EmergencyAlertEntity>>> {
  EmergencyAlertsNotifier(this._get, this._create)
      : super(const AsyncValue.loading());

  final GetAlertsUseCase    _get;
  final CreateAlertUseCase  _create;

  String? _municipalityId;

  Future<void> load(String municipalityId, {bool activeOnly = false}) async {
    _municipalityId = municipalityId;
    state = const AsyncValue.loading();
    final r = await _get(municipalityId, activeOnly: activeOnly);
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<bool> create(Map<String, dynamic> data) async {
    if (_municipalityId == null) return false;
    final r = await _create(_municipalityId!, data);
    return r.fold((_) => false, (_) { load(_municipalityId!); return true; });
  }
}

// ── Audit log notifier ────────────────────────────────────────────────────────

class AuditLogsNotifier
    extends StateNotifier<AsyncValue<List<AuditLogEntity>>> {
  AuditLogsNotifier(this._get) : super(const AsyncValue.loading());

  final GetAuditLogsUseCase _get;
  String? _municipalityId;
  String? _actionFilter;
  int     _page = 0;

  Future<void> load(String municipalityId,
      {String? action, bool refresh = false}) async {
    _municipalityId = municipalityId;
    _actionFilter   = action;
    if (refresh) _page = 0;
    state = const AsyncValue.loading();
    final r = await _get(municipalityId, action: action, page: _page);
    state = r.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<void> refresh() async {
    if (_municipalityId == null) return;
    await load(_municipalityId!, action: _actionFilter, refresh: true);
  }
}
