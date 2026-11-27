import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/analytics_entity.dart';
import '../repositories/officer_repository.dart';

class GetIssueTrendUseCase {
  const GetIssueTrendUseCase(this._repo);
  final OfficerRepository _repo;

  Future<Either<Failure, List<TrendPointEntity>>> call({
    required String municipalityId,
    int days = 30,
    String? departmentId,
  }) =>
      _repo.getIssueTrend(
          municipalityId: municipalityId, days: days, departmentId: departmentId);
}
