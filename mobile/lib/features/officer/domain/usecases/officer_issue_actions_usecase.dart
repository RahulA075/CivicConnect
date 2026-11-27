import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../features/issues/domain/entities/issue_entity.dart';
import '../entities/analytics_entity.dart';
import '../repositories/officer_repository.dart';

/// Bundles all mutating issue actions for the officer dashboard.
class OfficerIssueActionsUseCase {
  const OfficerIssueActionsUseCase(this._repo);
  final OfficerRepository _repo;

  Future<Either<Failure, IssueEntity>> accept(String issueId) =>
      _repo.acceptIssue(issueId);

  Future<Either<Failure, void>> reject(String issueId, String reason) =>
      _repo.rejectIssue(issueId, reason);

  Future<Either<Failure, IssueEntity>> assign(
          String issueId, String workerId, {String? note}) =>
      _repo.assignIssue(issueId, workerId, note: note);

  Future<Either<Failure, IssueEntity>> updateStatus(
          String issueId, String status, {String? note}) =>
      _repo.updateStatus(issueId, status, note: note);

  Future<Either<Failure, List<StatusHistoryEntity>>> getHistory(String issueId) =>
      _repo.getStatusHistory(issueId);

  Future<Either<Failure, List<WorkerEntity>>> getWorkers({
    required String departmentId,
    required String municipalityId,
  }) =>
      _repo.getDepartmentWorkers(
          departmentId: departmentId, municipalityId: municipalityId);
}
