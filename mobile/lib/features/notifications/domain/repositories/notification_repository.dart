import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/notification_entity.dart';

abstract interface class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 0,
    int size = 20,
  });

  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, void>> markRead(String id);

  Future<Either<Failure, void>> markAllRead();

  Future<Either<Failure, NotificationPreferencesEntity>> getPreferences();

  Future<Either<Failure, NotificationPreferencesEntity>> updatePreferences(
      NotificationPreferencesEntity prefs);
}

/// User notification preferences.
class NotificationPreferencesEntity {
  const NotificationPreferencesEntity({
    this.pushEnabled  = true,
    this.emailEnabled = true,
    this.smsEnabled   = false,
    this.eventOverrides = const {},
  });

  final bool                pushEnabled;
  final bool                emailEnabled;
  final bool                smsEnabled;
  final Map<String, bool>   eventOverrides;

  NotificationPreferencesEntity copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    Map<String, bool>? eventOverrides,
  }) =>
      NotificationPreferencesEntity(
        pushEnabled:    pushEnabled    ?? this.pushEnabled,
        emailEnabled:   emailEnabled   ?? this.emailEnabled,
        smsEnabled:     smsEnabled     ?? this.smsEnabled,
        eventOverrides: eventOverrides ?? this.eventOverrides,
      );
}
