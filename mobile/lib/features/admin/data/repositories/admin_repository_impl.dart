import 'package:dartz/dartz.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remote);
  final AdminRemoteDataSource _remote;

  // ── Departments ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<DepartmentEntity>>> getDepartments(
      String municipalityId) async {
    try { return Right(await _remote.getDepartments(municipalityId)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, DepartmentEntity>> createDepartment(
      String municipalityId, Map<String, dynamic> data) async {
    try { return Right(await _remote.createDepartment(municipalityId, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, DepartmentEntity>> updateDepartment(
      String id, Map<String, dynamic> data) async {
    try { return Right(await _remote.updateDepartment(id, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, void>> deactivateDepartment(String id) async {
    try { await _remote.deactivateDepartment(id); return const Right(null); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  // ── Categories ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories(
      String municipalityId) async {
    try { return Right(await _remote.getCategories(municipalityId)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, CategoryEntity>> createCategory(
      String municipalityId, Map<String, dynamic> data) async {
    try { return Right(await _remote.createCategory(municipalityId, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory(
      String id, Map<String, dynamic> data) async {
    try { return Right(await _remote.updateCategory(id, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, void>> deactivateCategory(String id) async {
    try { await _remote.deactivateCategory(id); return const Right(null); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  // ── SLA Policies ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<SlaPolicyEntity>>> getSlaPolicies(
      String municipalityId) async {
    try { return Right(await _remote.getSlaPolicies(municipalityId)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, SlaPolicyEntity>> createSlaPolicy(
      String municipalityId, Map<String, dynamic> data) async {
    try { return Right(await _remote.createSlaPolicy(municipalityId, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, SlaPolicyEntity>> updateSlaPolicy(
      String id, Map<String, dynamic> data) async {
    try { return Right(await _remote.updateSlaPolicy(id, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, void>> deactivateSlaPolicy(String id) async {
    try { await _remote.deactivateSlaPolicy(id); return const Right(null); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  // ── Escalation Rules ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<EscalationRuleEntity>>> getEscalationRules(
      String municipalityId) async {
    try { return Right(await _remote.getEscalationRules(municipalityId)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, EscalationRuleEntity>> createEscalationRule(
      String municipalityId, Map<String, dynamic> data) async {
    try { return Right(await _remote.createEscalationRule(municipalityId, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, EscalationRuleEntity>> updateEscalationRule(
      String id, Map<String, dynamic> data) async {
    try { return Right(await _remote.updateEscalationRule(id, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, void>> deactivateEscalationRule(String id) async {
    try { await _remote.deactivateEscalationRule(id); return const Right(null); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  // ── Users ────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<AdminUserEntity>>> getUsers(String municipalityId,
      {String? departmentId}) async {
    try {
      return Right(await _remote.getUsers(municipalityId,
          departmentId: departmentId));
    } on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, AdminUserEntity>> inviteUser(
      String municipalityId, Map<String, dynamic> data) async {
    try { return Right(await _remote.inviteUser(municipalityId, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, void>> deactivateUser(String userId) async {
    try { await _remote.deactivateUser(userId); return const Right(null); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, void>> reactivateUser(String userId) async {
    try { await _remote.reactivateUser(userId); return const Right(null); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  // ── Emergency Alerts ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<EmergencyAlertEntity>>> getAlerts(
      String municipalityId, {bool activeOnly = false}) async {
    try {
      return Right(
          await _remote.getAlerts(municipalityId, activeOnly: activeOnly));
    } on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, EmergencyAlertEntity>> createAlert(
      String municipalityId, Map<String, dynamic> data) async {
    try { return Right(await _remote.createAlert(municipalityId, data)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, void>> deactivateAlert(String id) async {
    try { await _remote.deactivateAlert(id); return const Right(null); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  // ── Audit Logs ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<AuditLogEntity>>> getAuditLogs(
      String municipalityId,
      {String? action, int page = 0, int size = 50}) async {
    try {
      return Right(await _remote.getAuditLogs(municipalityId,
          action: action, page: page, size: size));
    } on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }
}
