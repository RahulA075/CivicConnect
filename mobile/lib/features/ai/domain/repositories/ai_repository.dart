import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_analysis.dart';
import '../entities/duplicate_candidate.dart';

abstract class AiRepository {
  /// Full text (+ optional image) analysis of an issue being composed.
  Future<Either<Failure, AiAnalysis>> analyzeText({
    required String title,
    required String description,
    String? municipalityId,
    String? issueId,
    String? imageUrl,
  });

  /// Check for duplicate issues near the given coordinates.
  Future<Either<Failure, DuplicateCheckResult>> checkDuplicate({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 500,
  });

  /// Real-time smart suggestions as the citizen types.
  Future<Either<Failure, List<String>>> getSmartSuggestions({
    required String title,
    String? description,
    String? municipalityId,
  });

  /// Retrieve stored AI analysis for a submitted issue.
  Future<Either<Failure, AiAnalysis?>> getAnalysisForIssue(String issueId);
}
