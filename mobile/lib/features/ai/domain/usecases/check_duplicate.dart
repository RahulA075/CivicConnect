import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/duplicate_candidate.dart';
import '../repositories/ai_repository.dart';

class CheckDuplicate {
  final AiRepository repository;
  const CheckDuplicate(this.repository);

  Future<Either<Failure, DuplicateCheckResult>> call({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 500,
  }) =>
      repository.checkDuplicate(
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        municipalityId: municipalityId,
        radiusMetres: radiusMetres,
      );
}
