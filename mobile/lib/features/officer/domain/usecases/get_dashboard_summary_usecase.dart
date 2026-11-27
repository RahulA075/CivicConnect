import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/analytics_entity.dart';
import '../repositories/officer_repository.dart';

class GetDashboardSummaryUseCase {
  const GetDashboardSummaryUseCase(this._repo);
  final OfficerRepository _repo;

  Future<Either<Failure, DashboardSummaryEntity>> call(String municipalityId) =>
      _repo.getDashboardSummary(municipalityId);
}
