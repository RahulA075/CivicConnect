import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/admin_entities.dart';

abstract interface class AdminRepository {
  // ── Departments ────────────────────────────────────────────────────────────
  Future<Either<Failure, List<DepartmentEntity>>> getDepartments(String municipalityId);
  Future<Either<Failure, DepartmentEntity>> createDepartment(
      String municipalityId, Map<String, dynamic> data);
  Future<Either<Failure, DepartmentEntity>> updateDepartment(
      String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deactivateDepartment(String id);

  // ── Categories ─────────────────────────────────────────────────────────────
  Future<Either<Failure, List<CategoryEntity>>> getCategories(String municipalityId);
  Future<Either<Failure, CategoryEntity>> createCategory(
      String municipalityId, Map<String, dynamic> data);
  Future<Either<Failure, CategoryEntity>> updateCategory(
      String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deactivateCategory(String id);

  // ── SLA Policies ───────────────────────────────────────────────────────────
  Future<Either<Failure, List<SlaPolicyEntity>>> getSlaPolicies(String municipalityId);
  Future<Either<Failure, SlaPolicyEntity>> createSlaPolicy(
      String municipalityId, Map<String, dynamic> data);
  Future<Either<Failure, SlaPolicyEntity>> updateSlaPolicy(
      String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deactivateSlaPolicy(String id);

  // ── Escalation Rules ───────────────────────────────────────────────────────
  Future<Either<Failure, List<EscalationRuleEntity>>> getEscalationRules(
      String municipalityId);
  Future<Either<Failure, EscalationRuleEntity>> createEscalationRule(
      String municipalityId, Map<String, dynamic> data);
  Future<Either<Failure, EscalationRuleEntity>> updateEscalationRule(
      String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deactivateEscalationRule(String id);

  // ── Users ──────────────────────────────────────────────────────────────────
  Future<Either<Failure, List<AdminUserEntity>>> getUsers(
      String municipalityId, {String? departmentId});
  Future<Either<Failure, AdminUserEntity>> inviteUser(
      String municipalityId, Map<String, dynamic> data);
  Future<Either<Failure, void>> deactivateUser(String userId);
  Future<Either<Failure, void>> reactivateUser(String userId);

  // ── Emergency Alerts ───────────────────────────────────────────────────────
  Future<Either<Failure, List<EmergencyAlertEntity>>> getAlerts(
      String municipalityId, {bool activeOnly = false});
  Future<Either<Failure, EmergencyAlertEntity>> createAlert(
      String municipalityId, Map<String, dynamic> data);
  Future<Either<Failure, void>> deactivateAlert(String id);

  // ── Audit Logs ─────────────────────────────────────────────────────────────
  Future<Either<Failure, List<AuditLogEntity>>> getAuditLogs(
      String municipalityId, {String? action, int page = 0, int size = 50});
}
