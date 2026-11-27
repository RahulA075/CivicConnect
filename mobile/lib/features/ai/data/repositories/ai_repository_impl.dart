import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ai_analysis.dart';
import '../../domain/entities/duplicate_candidate.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource _remote;
  const AiRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, AiAnalysis>> analyzeText({
    required String title,
    required String description,
    String? municipalityId,
    String? issueId,
    String? imageUrl,
  }) async {
    try {
      final result = await _remote.analyzeText(
        title: title,
        description: description,
        municipalityId: municipalityId,
        issueId: issueId,
        imageUrl: imageUrl,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DuplicateCheckResult>> checkDuplicate({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 500,
  }) async {
    try {
      final result = await _remote.checkDuplicate(
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        municipalityId: municipalityId,
        radiusMetres: radiusMetres,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSmartSuggestions({
    required String title,
    String? description,
    String? municipalityId,
  }) async {
    try {
      final result = await _remote.getSmartSuggestions(
        title: title,
        description: description,
        municipalityId: municipalityId,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AiAnalysis?>> getAnalysisForIssue(
      String issueId) async {
    try {
      final result = await _remote.getAnalysisForIssue(issueId);
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure('AI service timed out');
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) return const UnauthorisedFailure();
    if (statusCode == 422) return const ValidationFailure('Invalid request');
    return ServerFailure(
        e.response?.data?['message']?.toString() ?? 'AI service error');
  }
}
