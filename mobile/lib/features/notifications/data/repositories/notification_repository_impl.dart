import 'package:dartz/dartz.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remote);
  final NotificationRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      return Right(await _remote.getNotifications(page: page, size: size));
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      return Right(await _remote.getUnreadCount());
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    try {
      await _remote.markRead(id);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    try {
      await _remote.markAllRead();
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> getPreferences() async {
    try {
      return Right(await _remote.getPreferences());
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> updatePreferences(
      NotificationPreferencesEntity prefs) async {
    try {
      final model = NotificationPreferencesModel(
        pushEnabled:    prefs.pushEnabled,
        emailEnabled:   prefs.emailEnabled,
        smsEnabled:     prefs.smsEnabled,
        eventOverrides: prefs.eventOverrides,
      );
      return Right(await _remote.updatePreferences(model));
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }
}
