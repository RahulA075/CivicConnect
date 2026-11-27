import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../features/issues/domain/entities/issue_entity.dart';
import '../entities/analytics_entity.dart';

abstract interface class OfficerRepository {
  // ── Issue queue ──────────────────────────────────────────────────────────
  Future<Either<Failure, List<IssueEntity>>> getDepartmentIssues({
    required String departmentId,
    String? status,
    int page,
    int size,
  });

  Future<Either<Failure, List<IssueEntity>>> getMyTasks();

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<Either<Failure, IssueEntity>> acceptIssue(String issueId);
  Future<Either<Failure, void>> rejectIssue(String issueId, String reason);
  Future<Either<Failure, IssueEntity>> assignIssue(String issueId, String workerId, {String? note});
  Future<Either<Failure, IssueEntity>> updateStatus(String issueId, String status, {String? note});

  // ── Timeline ─────────────────────────────────────────────────────────────
  Future<Either<Failure, List<StatusHistoryEntity>>> getStatusHistory(String issueId);

  // ── Workers ──────────────────────────────────────────────────────────────
  Future<Either<Failure, List<WorkerEntity>>> getDepartmentWorkers({
    required String departmentId,
    required String municipalityId,
  });

  // ── Analytics ────────────────────────────────────────────────────────────
  Future<Either<Failure, DashboardSummaryEntity>> getDashboardSummary(String municipalityId);
  Future<Either<Failure, List<TrendPointEntity>>> getIssueTrend({
    required String municipalityId,
    int days,
    String? departmentId,
  });
}
