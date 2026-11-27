import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/issue_repository.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);
  final IssueRepository _repository;

  Future<Either<Failure, List<Map<String, dynamic>>>> call(
          String municipalityId) =>
      _repository.getCategories(municipalityId);
}
