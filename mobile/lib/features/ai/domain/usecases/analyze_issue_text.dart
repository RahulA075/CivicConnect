import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_analysis.dart';
import '../repositories/ai_repository.dart';

class AnalyzeIssueText {
  final AiRepository repository;
  const AnalyzeIssueText(this.repository);

  Future<Either<Failure, AiAnalysis>> call({
    required String title,
    required String description,
    String? municipalityId,
    String? issueId,
    String? imageUrl,
  }) =>
      repository.analyzeText(
        title: title,
        description: description,
        municipalityId: municipalityId,
        issueId: issueId,
        imageUrl: imageUrl,
      );
}
