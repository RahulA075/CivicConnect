import 'package:dartz/dartz.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../features/issues/domain/entities/issue_entity.dart';
import '../../domain/entities/analytics_entity.dart';
import '../../domain/repositories/officer_repository.dart';
import '../datasources/officer_remote_datasource.dart';

class OfficerRepositoryImpl implements OfficerRepository {
  const OfficerRepositoryImpl(this._remote);
  final OfficerRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<IssueEntity>>> getDepartmentIssues({
    required String departmentId,
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      return Right(await _remote.getDepartmentIssues(
          departmentId: departmentId, status: status, page: page, size: size));
    } on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, List<IssueEntity>>> getMyTasks() async {
    try { return Right(await _remote.getMyTasks()); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, IssueEntity>> acceptIssue(String issueId) async {
    try { return Right(await _remote.acceptIssue(issueId)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, void>> rejectIssue(String issueId, String reason) async {
    try { await _remote.rejectIssue(issueId, reason); return const Right(null); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, IssueEntity>> assignIssue(String issueId, String workerId,
      {String? note}) async {
    try { return Right(await _remote.assignIssue(issueId, workerId, note: note)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, IssueEntity>> updateStatus(String issueId, String status,
      {String? note}) async {
    try { return Right(await _remote.updateStatus(issueId, status, note: note)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, List<StatusHistoryEntity>>> getStatusHistory(String issueId) async {
    try { return Right(await _remote.getStatusHistory(issueId)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, List<WorkerEntity>>> getDepartmentWorkers({
    required String departmentId,
    required String municipalityId,
  }) async {
    try {
      return Right(await _remote.getDepartmentWorkers(
          departmentId: departmentId, municipalityId: municipalityId));
    } on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, DashboardSummaryEntity>> getDashboardSummary(
      String municipalityId) async {
    try { return Right(await _remote.getDashboardSummary(municipalityId)); }
    on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }

  @override
  Future<Either<Failure, List<TrendPointEntity>>> getIssueTrend({
    required String municipalityId,
    int days = 30,
    String? departmentId,
  }) async {
    try {
      return Right(await _remote.getIssueTrend(
          municipalityId: municipalityId, days: days, departmentId: departmentId));
    } on AppException catch (e) { return Left(ErrorHandler.toFailure(e)); }
  }
}
