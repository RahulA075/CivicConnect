import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      final profile = await _remote.getProfile();
      return Right(profile);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? bio,
  }) async {
    try {
      final profile = await _remote.updateProfile(
        fullName: fullName, phone: phone, bio: bio);
      return Right(profile);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(File image) async {
    try {
      final url = await _remote.uploadAvatar(image);
      return Right(url);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }
}
