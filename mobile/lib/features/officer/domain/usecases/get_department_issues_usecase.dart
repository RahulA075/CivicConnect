import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../features/issues/domain/entities/issue_entity.dart';
import '../repositories/officer_repository.dart';

class GetDepartmentIssuesUseCase {
  const GetDepartmentIssuesUseCase(this._repo);
  final OfficerRepository _repo;

  Future<Either<Failure, List<IssueEntity>>> call({
    required String departmentId,
    String? status,
    int page = 0,
    int size = 20,
  }) =>
      _repo.getDepartmentIssues(
          departmentId: departmentId, status: status, page: page, size: size);
}
