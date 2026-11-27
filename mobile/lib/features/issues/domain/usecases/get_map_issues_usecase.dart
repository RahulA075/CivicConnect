import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/nearby_issue_entity.dart';
import '../repositories/issue_repository.dart';

class GetMapIssuesUseCase {
  const GetMapIssuesUseCase(this._repository);
  final IssueRepository _repository;

  Future<Either<Failure, List<NearbyIssueEntity>>> call({
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres   = 5000,
    String? status,
    String? categoryId,
  }) =>
      _repository.getMapIssues(
        latitude:       latitude,
        longitude:      longitude,
        municipalityId: municipalityId,
        radiusMetres:   radiusMetres,
        status:         status,
        categoryId:     categoryId,
      );
}
