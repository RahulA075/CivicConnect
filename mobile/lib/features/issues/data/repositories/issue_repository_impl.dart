import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/nearby_issue_entity.dart';
import '../../domain/repositories/issue_repository.dart';
import '../datasources/issue_remote_datasource.dart';

class IssueRepositoryImpl implements IssueRepository {
  const IssueRepositoryImpl(this._remote);
  final IssueRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<IssueEntity>>> getPublicFeed({
    required String municipalityId,
    int page = 0,
    int size = 20,
    String? categoryId,
    String? status,
  }) async {
    try {
      final issues = await _remote.getPublicFeed(
        municipalityId: municipalityId,
        page: page,
        size: size,
        categoryId: categoryId,
        status: status,
      );
      return Right(issues);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<IssueEntity>>> getMyIssues({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final issues = await _remote.getMyIssues(page: page, size: size);
      return Right(issues);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<NearbyIssueEntity>>> getNearbyIssues({
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 200,
  }) async {
    try {
      final issues = await _remote.getNearbyIssues(
        latitude: latitude,
        longitude: longitude,
        municipalityId: municipalityId,
        radiusMetres: radiusMetres,
      );
      return Right(issues);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<NearbyIssueEntity>>> getMapIssues({
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 5000,
    String? status,
    String? categoryId,
  }) async {
    try {
      final issues = await _remote.getMapIssues(
        latitude: latitude,
        longitude: longitude,
        municipalityId: municipalityId,
        radiusMetres: radiusMetres,
        status: status,
        categoryId: categoryId,
      );
      return Right(issues);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> getIssueById(String id) async {
    try {
      final issue = await _remote.getIssueById(id);
      return Right(issue);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> reportIssue({
    required String title,
    required String description,
    required String categoryId,
    required double latitude,
    required double longitude,
    required String address,
    String? priority,
    bool anonymous = false,
    List<File> images = const [],
  }) async {
    try {
      final issue = await _remote.reportIssue(
        title: title,
        description: description,
        categoryId: categoryId,
        latitude: latitude,
        longitude: longitude,
        address: address,
        priority: priority,
        anonymous: anonymous,
        images: images,
      );
      return Right(issue);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> upvoteIssue(String id) async {
    try {
      final issue = await _remote.upvoteIssue(id);
      return Right(issue);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> trackIssue(String trackingId) async {
    try {
      final issue = await _remote.trackIssue(trackingId);
      return Right(issue);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCategories(
      String municipalityId) async {
    try {
      final cats = await _remote.getCategories(municipalityId);
      return Right(cats);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }
}
