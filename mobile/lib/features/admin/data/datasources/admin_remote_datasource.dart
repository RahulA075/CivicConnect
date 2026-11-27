import 'package:dio/dio.dart';

import '../../../../core/error/error_handler.dart';
import '../models/admin_models.dart';

abstract interface class AdminRemoteDataSource {
  // Departments
  Future<List<DepartmentModel>> getDepartments(String municipalityId);
  Future<DepartmentModel> createDepartment(String municipalityId, Map<String, dynamic> data);
  Future<DepartmentModel> updateDepartment(String id, Map<String, dynamic> data);
  Future<void> deactivateDepartment(String id);

  // Categories
  Future<List<CategoryModel>> getCategories(String municipalityId);
  Future<CategoryModel> createCategory(String municipalityId, Map<String, dynamic> data);
  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> data);
  Future<void> deactivateCategory(String id);

  // SLA Policies
  Future<List<SlaPolicyModel>> getSlaPolicies(String municipalityId);
  Future<SlaPolicyModel> createSlaPolicy(String municipalityId, Map<String, dynamic> data);
  Future<SlaPolicyModel> updateSlaPolicy(String id, Map<String, dynamic> data);
  Future<void> deactivateSlaPolicy(String id);

  // Escalation Rules
  Future<List<EscalationRuleModel>> getEscalationRules(String municipalityId);
  Future<EscalationRuleModel> createEscalationRule(String municipalityId, Map<String, dynamic> data);
  Future<EscalationRuleModel> updateEscalationRule(String id, Map<String, dynamic> data);
  Future<void> deactivateEscalationRule(String id);

  // Users
  Future<List<AdminUserModel>> getUsers(String municipalityId, {String? departmentId});
  Future<AdminUserModel> inviteUser(String municipalityId, Map<String, dynamic> data);
  Future<void> deactivateUser(String userId);
  Future<void> reactivateUser(String userId);

  // Emergency Alerts
  Future<List<EmergencyAlertModel>> getAlerts(String municipalityId, {bool activeOnly = false});
  Future<EmergencyAlertModel> createAlert(String municipalityId, Map<String, dynamic> data);
  Future<void> deactivateAlert(String id);

  // Audit Logs
  Future<List<AuditLogModel>> getAuditLogs(
      String municipalityId, {String? action, int page = 0, int size = 50});
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  const AdminRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  static const _base = '/api/v1/admin';

  dynamic _data(Map<String, dynamic> envelope) =>
      envelope.containsKey('data') ? envelope['data'] : envelope;

  List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    final list = raw as List<dynamic>? ?? [];
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Departments ─────────────────────────────────────────────────────────────

  @override
  Future<List<DepartmentModel>> getDepartments(String municipalityId) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/departments');
      return _list(_data(r.data!), DepartmentModel.fromJson);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<DepartmentModel> createDepartment(
      String municipalityId, Map<String, dynamic> data) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/departments', data: data);
      return DepartmentModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<DepartmentModel> updateDepartment(
      String id, Map<String, dynamic> data) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
          '$_base/departments/$id', data: data);
      return DepartmentModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<void> deactivateDepartment(String id) async {
    try { await _dio.post<void>('$_base/departments/$id/deactivate'); }
    catch (e) { throw ErrorHandler.handle(e); }
  }

  // ── Categories ──────────────────────────────────────────────────────────────

  @override
  Future<List<CategoryModel>> getCategories(String municipalityId) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/categories');
      return _list(_data(r.data!), CategoryModel.fromJson);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<CategoryModel> createCategory(
      String municipalityId, Map<String, dynamic> data) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/categories', data: data);
      return CategoryModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<CategoryModel> updateCategory(
      String id, Map<String, dynamic> data) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
          '$_base/categories/$id', data: data);
      return CategoryModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<void> deactivateCategory(String id) async {
    try { await _dio.post<void>('$_base/categories/$id/deactivate'); }
    catch (e) { throw ErrorHandler.handle(e); }
  }

  // ── SLA Policies ────────────────────────────────────────────────────────────

  @override
  Future<List<SlaPolicyModel>> getSlaPolicies(String municipalityId) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/sla-policies');
      return _list(_data(r.data!), SlaPolicyModel.fromJson);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<SlaPolicyModel> createSlaPolicy(
      String municipalityId, Map<String, dynamic> data) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/sla-policies', data: data);
      return SlaPolicyModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<SlaPolicyModel> updateSlaPolicy(
      String id, Map<String, dynamic> data) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
          '$_base/sla-policies/$id', data: data);
      return SlaPolicyModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<void> deactivateSlaPolicy(String id) async {
    try { await _dio.post<void>('$_base/sla-policies/$id/deactivate'); }
    catch (e) { throw ErrorHandler.handle(e); }
  }

  // ── Escalation Rules ────────────────────────────────────────────────────────

  @override
  Future<List<EscalationRuleModel>> getEscalationRules(
      String municipalityId) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/escalation-rules');
      return _list(_data(r.data!), EscalationRuleModel.fromJson);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<EscalationRuleModel> createEscalationRule(
      String municipalityId, Map<String, dynamic> data) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/escalation-rules', data: data);
      return EscalationRuleModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<EscalationRuleModel> updateEscalationRule(
      String id, Map<String, dynamic> data) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
          '$_base/escalation-rules/$id', data: data);
      return EscalationRuleModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<void> deactivateEscalationRule(String id) async {
    try { await _dio.post<void>('$_base/escalation-rules/$id/deactivate'); }
    catch (e) { throw ErrorHandler.handle(e); }
  }

  // ── Users ────────────────────────────────────────────────────────────────────

  @override
  Future<List<AdminUserModel>> getUsers(String municipalityId,
      {String? departmentId}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '$_base/municipalities/$municipalityId/users',
        queryParameters: {
          if (departmentId != null) 'departmentId': departmentId,
          'size': 200,
        },
      );
      final paged = _data(r.data!) as Map<String, dynamic>;
      final list  = paged['content'] as List<dynamic>? ?? [];
      return list.map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<AdminUserModel> inviteUser(
      String municipalityId, Map<String, dynamic> data) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/users/invite', data: data);
      return AdminUserModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<void> deactivateUser(String userId) async {
    try { await _dio.post<void>('$_base/users/$userId/deactivate'); }
    catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<void> reactivateUser(String userId) async {
    try { await _dio.post<void>('$_base/users/$userId/reactivate'); }
    catch (e) { throw ErrorHandler.handle(e); }
  }

  // ── Emergency Alerts ────────────────────────────────────────────────────────

  @override
  Future<List<EmergencyAlertModel>> getAlerts(String municipalityId,
      {bool activeOnly = false}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '$_base/municipalities/$municipalityId/alerts',
        queryParameters: {'activeOnly': activeOnly, 'size': 100},
      );
      final paged = _data(r.data!) as Map<String, dynamic>;
      final list  = paged['content'] as List<dynamic>? ?? [];
      return list.map((e) => EmergencyAlertModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<EmergencyAlertModel> createAlert(
      String municipalityId, Map<String, dynamic> data) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
          '$_base/municipalities/$municipalityId/alerts', data: data);
      return EmergencyAlertModel.fromJson(_data(r.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<void> deactivateAlert(String id) async {
    try { await _dio.post<void>('$_base/alerts/$id/deactivate'); }
    catch (e) { throw ErrorHandler.handle(e); }
  }

  // ── Audit Logs ───────────────────────────────────────────────────────────────

  @override
  Future<List<AuditLogModel>> getAuditLogs(String municipalityId,
      {String? action, int page = 0, int size = 50}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '$_base/municipalities/$municipalityId/audit-logs',
        queryParameters: {
          'page': page, 'size': size,
          if (action != null) 'action': action,
        },
      );
      final paged = _data(r.data!) as Map<String, dynamic>;
      final list  = paged['content'] as List<dynamic>? ?? [];
      return list.map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) { throw ErrorHandler.handle(e); }
  }
}
