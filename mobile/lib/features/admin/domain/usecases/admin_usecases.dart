import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/admin_entities.dart';
import '../repositories/admin_repository.dart';

// ── Departments ───────────────────────────────────────────────────────────────

class GetDepartmentsUseCase {
  const GetDepartmentsUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, List<DepartmentEntity>>> call(String municipalityId) =>
      _repo.getDepartments(municipalityId);
}

class CreateDepartmentUseCase {
  const CreateDepartmentUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, DepartmentEntity>> call(
          String municipalityId, Map<String, dynamic> data) =>
      _repo.createDepartment(municipalityId, data);
}

class UpdateDepartmentUseCase {
  const UpdateDepartmentUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, DepartmentEntity>> call(
          String id, Map<String, dynamic> data) =>
      _repo.updateDepartment(id, data);
}

class DeactivateDepartmentUseCase {
  const DeactivateDepartmentUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, void>> call(String id) => _repo.deactivateDepartment(id);
}

// ── Categories ────────────────────────────────────────────────────────────────

class GetCategoriesAdminUseCase {
  const GetCategoriesAdminUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, List<CategoryEntity>>> call(String municipalityId) =>
      _repo.getCategories(municipalityId);
}

class CreateCategoryUseCase {
  const CreateCategoryUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, CategoryEntity>> call(
          String municipalityId, Map<String, dynamic> data) =>
      _repo.createCategory(municipalityId, data);
}

class UpdateCategoryUseCase {
  const UpdateCategoryUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, CategoryEntity>> call(
          String id, Map<String, dynamic> data) =>
      _repo.updateCategory(id, data);
}

// ── SLA Policies ──────────────────────────────────────────────────────────────

class GetSlaPoliciesUseCase {
  const GetSlaPoliciesUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, List<SlaPolicyEntity>>> call(String municipalityId) =>
      _repo.getSlaPolicies(municipalityId);
}

class CreateSlaPolicyUseCase {
  const CreateSlaPolicyUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, SlaPolicyEntity>> call(
          String municipalityId, Map<String, dynamic> data) =>
      _repo.createSlaPolicy(municipalityId, data);
}

class UpdateSlaPolicyUseCase {
  const UpdateSlaPolicyUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, SlaPolicyEntity>> call(
          String id, Map<String, dynamic> data) =>
      _repo.updateSlaPolicy(id, data);
}

// ── Escalation Rules ──────────────────────────────────────────────────────────

class GetEscalationRulesUseCase {
  const GetEscalationRulesUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, List<EscalationRuleEntity>>> call(String municipalityId) =>
      _repo.getEscalationRules(municipalityId);
}

class CreateEscalationRuleUseCase {
  const CreateEscalationRuleUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, EscalationRuleEntity>> call(
          String municipalityId, Map<String, dynamic> data) =>
      _repo.createEscalationRule(municipalityId, data);
}

class UpdateEscalationRuleUseCase {
  const UpdateEscalationRuleUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, EscalationRuleEntity>> call(
          String id, Map<String, dynamic> data) =>
      _repo.updateEscalationRule(id, data);
}

// ── Users ─────────────────────────────────────────────────────────────────────

class GetAdminUsersUseCase {
  const GetAdminUsersUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, List<AdminUserEntity>>> call(
          String municipalityId, {String? departmentId}) =>
      _repo.getUsers(municipalityId, departmentId: departmentId);
}

class InviteUserUseCase {
  const InviteUserUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, AdminUserEntity>> call(
          String municipalityId, Map<String, dynamic> data) =>
      _repo.inviteUser(municipalityId, data);
}

class AdminUserActionsUseCase {
  const AdminUserActionsUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, void>> deactivate(String userId) =>
      _repo.deactivateUser(userId);
  Future<Either<Failure, void>> reactivate(String userId) =>
      _repo.reactivateUser(userId);
}

// ── Emergency Alerts ──────────────────────────────────────────────────────────

class GetAlertsUseCase {
  const GetAlertsUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, List<EmergencyAlertEntity>>> call(
          String municipalityId, {bool activeOnly = false}) =>
      _repo.getAlerts(municipalityId, activeOnly: activeOnly);
}

class CreateAlertUseCase {
  const CreateAlertUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, EmergencyAlertEntity>> call(
          String municipalityId, Map<String, dynamic> data) =>
      _repo.createAlert(municipalityId, data);
}

// ── Audit Logs ────────────────────────────────────────────────────────────────

class GetAuditLogsUseCase {
  const GetAuditLogsUseCase(this._repo);
  final AdminRepository _repo;
  Future<Either<Failure, List<AuditLogEntity>>> call(
          String municipalityId, {String? action, int page = 0}) =>
      _repo.getAuditLogs(municipalityId, action: action, page: page);
}
