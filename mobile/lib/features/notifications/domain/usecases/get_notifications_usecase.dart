import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, List<NotificationEntity>>> call({int page = 0}) =>
      _repository.getNotifications(page: page);
}

class GetUnreadCountUseCase {
  const GetUnreadCountUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, int>> call() => _repository.getUnreadCount();
}

class MarkReadUseCase {
  const MarkReadUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, void>> call(String id) => _repository.markRead(id);
}

class MarkAllReadUseCase {
  const MarkAllReadUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, void>> call() => _repository.markAllRead();
}

class GetNotificationPrefsUseCase {
  const GetNotificationPrefsUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, NotificationPreferencesEntity>> call() =>
      _repository.getPreferences();
}

class UpdateNotificationPrefsUseCase {
  const UpdateNotificationPrefsUseCase(this._repository);
  final NotificationRepository _repository;

  Future<Either<Failure, NotificationPreferencesEntity>> call(
          NotificationPreferencesEntity prefs) =>
      _repository.updatePreferences(prefs);
}
