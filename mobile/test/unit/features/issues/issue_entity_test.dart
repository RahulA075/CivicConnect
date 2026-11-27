import 'package:flutter_test/flutter_test.dart';

import 'package:civicconnect/features/issues/domain/entities/issue_entity.dart';

/// Unit tests for [IssueEntity] — pure domain logic, no external dependencies.
void main() {
  group('IssueEntity', () {
    final base = DateTime(2025, 7, 1);

    IssueEntity build({
      String status        = 'SUBMITTED',
      bool   isOverdue     = false,
      bool   isUpvotedByMe = false,
      int    upvoteCount   = 0,
    }) =>
        IssueEntity(
          id:           'issue-001',
          trackingId:   'CC-2025-0001',
          title:        'Pothole near bus stop',
          description:  'Large pothole causing accidents',
          status:       status,
          priority:     'HIGH',
          categoryName: 'Roads',
          latitude:     12.9716,
          longitude:    77.5946,
          address:      'MG Road, Bengaluru',
          upvoteCount:  upvoteCount,
          createdAt:    base,
          isOverdue:    isOverdue,
          isUpvotedByMe: isUpvotedByMe,
        );

    // ── Equatable ────────────────────────────────────────────────────────

    test('two identical entities are equal', () {
      expect(build(), equals(build()));
    });

    test('entities with different IDs are not equal', () {
      final a = build();
      final b = IssueEntity(
        id:           'issue-002',
        trackingId:   'CC-2025-0002',
        title:        'Different issue',
        description:  'Description',
        status:       'SUBMITTED',
        priority:     'LOW',
        categoryName: 'Water',
        latitude:     13.0,
        longitude:    77.6,
        address:      'Other Street',
        upvoteCount:  0,
        createdAt:    base,
      );
      expect(a, isNot(equals(b)));
    });

    // ── Status helpers ────────────────────────────────────────────────────

    test('status can be accessed correctly', () {
      expect(build(status: 'SUBMITTED').status, equals('SUBMITTED'));
      expect(build(status: 'IN_PROGRESS').status, equals('IN_PROGRESS'));
      expect(build(status: 'RESOLVED').status, equals('RESOLVED'));
      expect(build(status: 'CLOSED').status, equals('CLOSED'));
    });

    // ── isOverdue flag ────────────────────────────────────────────────────

    test('isOverdue defaults to false', () {
      expect(build().isOverdue, isFalse);
    });

    test('isOverdue can be set to true', () {
      expect(build(isOverdue: true).isOverdue, isTrue);
    });

    // ── upvote state ──────────────────────────────────────────────────────

    test('isUpvotedByMe defaults to false', () {
      expect(build().isUpvotedByMe, isFalse);
    });

    test('upvoteCount reflects correct value', () {
      expect(build(upvoteCount: 42).upvoteCount, equals(42));
    });

    // ── imageUrls default ─────────────────────────────────────────────────

    test('imageUrls defaults to empty list', () {
      expect(build().imageUrls, isEmpty);
    });

    // ── commentCount default ──────────────────────────────────────────────

    test('commentCount defaults to zero', () {
      expect(build().commentCount, isZero);
    });

    // ── categoryColor default ─────────────────────────────────────────────

    test('categoryColor defaults to #1565C0', () {
      expect(build().categoryColor, equals('#1565C0'));
    });
  });
}
