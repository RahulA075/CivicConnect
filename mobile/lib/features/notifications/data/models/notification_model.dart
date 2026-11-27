import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.eventType,
    required super.channel,
    required super.createdAt,
    super.isRead,
    super.issueId,
    super.actionUrl,
    super.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id:        j['id']        as String,
        title:     j['title']     as String,
        body:      j['body']      as String,
        eventType: j['eventType'] as String? ?? 'SYSTEM',
        channel:   j['channel']   as String? ?? 'PUSH',
        createdAt: DateTime.parse(j['createdAt'] as String),
        isRead:    j['read']      as bool? ?? j['isRead'] as bool? ?? false,
        issueId:   j['issueId']   as String?,
        actionUrl: j['actionUrl'] as String?,
        readAt: j['readAt'] != null
            ? DateTime.parse(j['readAt'] as String)
            : null,
      );
}

class NotificationPreferencesModel extends NotificationPreferencesEntity {
  const NotificationPreferencesModel({
    super.pushEnabled,
    super.emailEnabled,
    super.smsEnabled,
    super.eventOverrides,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> j) {
    final raw = j['eventOverrides'] as Map<String, dynamic>? ?? {};
    final overrides = raw.map((k, v) => MapEntry(k, v as bool? ?? false));
    return NotificationPreferencesModel(
      pushEnabled:    j['pushEnabled']  as bool? ?? true,
      emailEnabled:   j['emailEnabled'] as bool? ?? true,
      smsEnabled:     j['smsEnabled']   as bool? ?? false,
      eventOverrides: overrides,
    );
  }

  Map<String, dynamic> toJson() => {
        'pushEnabled':    pushEnabled,
        'emailEnabled':   emailEnabled,
        'smsEnabled':     smsEnabled,
        'eventOverrides': eventOverrides,
      };
}
