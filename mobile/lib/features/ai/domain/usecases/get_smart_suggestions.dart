import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/ai_repository.dart';

class GetSmartSuggestions {
  final AiRepository repository;
  const GetSmartSuggestions(this.repository);

  Future<Either<Failure, List<String>>> call({
    required String title,
    String? description,
    String? municipalityId,
  }) =>
      repository.getSmartSuggestions(
        title: title,
        description: description,
        municipalityId: municipalityId,
      );
}
