import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/issue_entity.dart';
import '../repositories/issue_repository.dart';

class ReportIssueUseCase {
  const ReportIssueUseCase(this._repository);
  final IssueRepository _repository;

  Future<Either<Failure, IssueEntity>> call({
    required String title,
    required String description,
    required String categoryId,
    required double latitude,
    required double longitude,
    required String address,
    String? priority,
    bool anonymous = false,
    List<File> images = const [],
  }) =>
      _repository.reportIssue(
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
}
