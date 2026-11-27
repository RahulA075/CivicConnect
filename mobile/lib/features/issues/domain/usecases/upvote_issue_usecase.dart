import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/issue_entity.dart';
import '../repositories/issue_repository.dart';

class UpvoteIssueUseCase {
  const UpvoteIssueUseCase(this._repository);
  final IssueRepository _repository;

  Future<Either<Failure, IssueEntity>> call(String issueId) =>
      _repository.upvoteIssue(issueId);
}
