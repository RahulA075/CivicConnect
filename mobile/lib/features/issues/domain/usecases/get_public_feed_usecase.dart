import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/issue_entity.dart';
import '../repositories/issue_repository.dart';

class GetPublicFeedUseCase {
  const GetPublicFeedUseCase(this._repository);
  final IssueRepository _repository;

  Future<Either<Failure, List<IssueEntity>>> call({
    required String municipalityId,
    int page = 0,
    String? categoryId,
    String? status,
  }) =>
      _repository.getPublicFeed(
        municipalityId: municipalityId,
        page: page,
        categoryId: categoryId,
        status: status,
      );
}
