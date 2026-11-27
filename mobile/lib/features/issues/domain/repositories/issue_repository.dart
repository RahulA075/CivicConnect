import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/issue_entity.dart';
import '../entities/nearby_issue_entity.dart';

abstract interface class IssueRepository {
  Future<Either<Failure, List<IssueEntity>>> getPublicFeed({
    required String municipalityId,
    int page,
    int size,
    String? categoryId,
    String? status,
  });

  Future<Either<Failure, List<IssueEntity>>> getMyIssues({int page, int size});

  Future<Either<Failure, List<NearbyIssueEntity>>> getNearbyIssues({
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres,
  });

  /// Full map issues — public endpoint, includes accurate lat/lng.
  Future<Either<Failure, List<NearbyIssueEntity>>> getMapIssues({
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres,
    String? status,
    String? categoryId,
  });

  Future<Either<Failure, IssueEntity>> getIssueById(String id);

  Future<Either<Failure, IssueEntity>> reportIssue({
    required String title,
    required String description,
    required String categoryId,
    required double latitude,
    required double longitude,
    required String address,
    String? priority,
    bool anonymous,
    List<File> images,
  });

  Future<Either<Failure, IssueEntity>> upvoteIssue(String id);

  Future<Either<Failure, IssueEntity>> trackIssue(String trackingId);

  Future<Either<Failure, List<Map<String, dynamic>>>> getCategories(
      String municipalityId);
}
