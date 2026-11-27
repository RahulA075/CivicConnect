import 'package:equatable/equatable.dart';

/// Notification event types (mirrors backend eventType strings).
abstract final class NotifType {
  static const issueSubmitted = 'ISSUE_SUBMITTED';
  static const statusChange   = 'STATUS_CHANGE';
  static const assignment     = 'ASSIGNMENT';
  static const nearbyIssue    = 'NEARBY_ISSUE';
  static const emergencyAlert = 'EMERGENCY_ALERT';
  static const announcement   = 'ANNOUNCEMENT';
  static const system         = 'SYSTEM';
}

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.eventType,
    required this.channel,
    required this.createdAt,
    this.isRead      = false,
    this.issueId,
    this.actionUrl,
    this.readAt,
  });

  final String    id;
  final String    title;
  final String    body;
  final String    eventType;  // NotifType constant
  final String    channel;    // PUSH | EMAIL | SMS
  final DateTime  createdAt;
  final bool      isRead;
  final String?   issueId;
  final String?   actionUrl;
  final DateTime? readAt;

  // ── Convenience helpers ───────────────────────────────────────────────────

  bool get isEmergency  => eventType == NotifType.emergencyAlert;
  bool get isNearby     => eventType == NotifType.nearbyIssue;
  bool get isAnnounce   => eventType == NotifType.announcement;
  bool get isIssueUpdate =>
      eventType == NotifType.statusChange ||
      eventType == NotifType.issueSubmitted ||
      eventType == NotifType.assignment;

  @override
  List<Object?> get props =>
      [id, title, body, eventType, channel, createdAt, isRead, issueId];
}
