import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/issue_entity.dart';
import '../repositories/issue_repository.dart';

class GetMyIssuesUseCase {
  const GetMyIssuesUseCase(this._repository);
  final IssueRepository _repository;

  Future<Either<Failure, List<IssueEntity>>> call({int page = 0}) =>
      _repository.getMyIssues(page: page);
}
