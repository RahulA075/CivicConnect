import 'package:flutter_test/flutter_test.dart';

import 'package:civicconnect/features/notifications/domain/entities/notification_entity.dart';
import 'package:civicconnect/features/notifications/domain/repositories/notification_repository.dart';

/// Unit tests for [NotificationEntity] — no external dependencies.
void main() {
  group('NotificationEntity', () {
    final baseDate = DateTime(2025, 7, 1);

    NotificationEntity build({
      String eventType = NotifType.statusChange,
      bool isRead      = false,
    }) =>
        NotificationEntity(
          id:        'notif-001',
          title:     'Issue Updated',
          body:      'Your issue CC-001 has been updated',
          eventType: eventType,
          channel:   'PUSH',
          createdAt: baseDate,
          isRead:    isRead,
          issueId:   'issue-001',
        );

    // ── isEmergency ──────────────────────────────────────────────────────

    test('isEmergency returns true for EMERGENCY_ALERT', () {
      final n = build(eventType: NotifType.emergencyAlert);
      expect(n.isEmergency, isTrue);
    });

    test('isEmergency returns false for STATUS_CHANGE', () {
      final n = build(eventType: NotifType.statusChange);
      expect(n.isEmergency, isFalse);
    });

    // ── isNearby ─────────────────────────────────────────────────────────

    test('isNearby returns true for NEARBY_ISSUE', () {
      final n = build(eventType: NotifType.nearbyIssue);
      expect(n.isNearby, isTrue);
    });

    // ── isIssueUpdate ─────────────────────────────────────────────────────

    test('isIssueUpdate returns true for STATUS_CHANGE', () {
      expect(build(eventType: NotifType.statusChange).isIssueUpdate, isTrue);
    });

    test('isIssueUpdate returns true for ASSIGNMENT', () {
      expect(build(eventType: NotifType.assignment).isIssueUpdate, isTrue);
    });

    test('isIssueUpdate returns true for ISSUE_SUBMITTED', () {
      expect(build(eventType: NotifType.issueSubmitted).isIssueUpdate, isTrue);
    });

    test('isIssueUpdate returns false for EMERGENCY_ALERT', () {
      expect(build(eventType: NotifType.emergencyAlert).isIssueUpdate, isFalse);
    });

    // ── isAnnounce ────────────────────────────────────────────────────────

    test('isAnnounce returns true for ANNOUNCEMENT', () {
      expect(build(eventType: NotifType.announcement).isAnnounce, isTrue);
    });

    // ── isRead flag ───────────────────────────────────────────────────────

    test('isRead defaults to false', () {
      expect(build().isRead, isFalse);
    });

    test('isRead can be set to true', () {
      expect(build(isRead: true).isRead, isTrue);
    });

    // ── Equatable / props ─────────────────────────────────────────────────

    test('two entities with same fields are equal', () {
      final a = build();
      final b = build();
      expect(a, equals(b));
    });

    test('entities with different IDs are not equal', () {
      final a = NotificationEntity(
        id: 'notif-001', title: 'T', body: 'B',
        eventType: NotifType.statusChange, channel: 'PUSH',
        createdAt: baseDate,
      );
      final b = NotificationEntity(
        id: 'notif-002', title: 'T', body: 'B',
        eventType: NotifType.statusChange, channel: 'PUSH',
        createdAt: baseDate,
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ── NotificationPreferencesEntity ─────────────────────────────────────

  group('NotificationPreferencesEntity', () {
    test('default values are correct', () {
      const prefs = NotificationPreferencesEntity();
      expect(prefs.pushEnabled,  isTrue);
      expect(prefs.emailEnabled, isTrue);
      expect(prefs.smsEnabled,   isFalse);
      expect(prefs.eventOverrides, isEmpty);
    });

    test('copyWith overrides individual fields', () {
      const prefs = NotificationPreferencesEntity();
      final updated = prefs.copyWith(smsEnabled: true, pushEnabled: false);

      expect(updated.smsEnabled,   isTrue);
      expect(updated.pushEnabled,  isFalse);
      expect(updated.emailEnabled, isTrue); // unchanged
    });

    test('copyWith does not mutate original', () {
      const prefs = NotificationPreferencesEntity();
      prefs.copyWith(pushEnabled: false);
      expect(prefs.pushEnabled, isTrue); // original unchanged
    });
  });
}
