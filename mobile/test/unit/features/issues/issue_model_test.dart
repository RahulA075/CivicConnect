import 'package:flutter_test/flutter_test.dart';

import 'package:civicconnect/features/issues/data/models/issue_model.dart';

// Shape returned by the backend IssueResponse DTO (GET /api/v1/issues/{id}).
Map<String, dynamic> _backendIssueJson() => {
      'id': '65620cd6-81f0-489e-9a5b-f7c00afe7894',
      'trackingId': 'CC-2026-00001',
      'title': 'Large pothole on main road',
      'description': 'Deep pothole near the bus stop causing accidents',
      'status': 'SUBMITTED',
      'priority': 'MEDIUM',
      'overdue': false,
      'upvoteCount': 1,
      'commentCount': 0,
      'latitude': 13.08,
      'longitude': 80.27,
      'addressText': 'Main Rd',
      'createdAt': '2026-11-27T15:05:55.635112Z',
      'categoryName': 'Pothole',
      'categoryColor': '#1565C0',
      'categoryId': '33333333-3333-3333-3333-333333333333',
      'departmentName': 'Roads',
      'reporterName': 'Smoke Test',
      'imageUrls': ['https://cdn.example.com/a.jpg', 'https://cdn.example.com/b.jpg'],
      'previewImageUrl': 'https://cdn.example.com/a.jpg',
      'assignedTo': 'Field Worker',
      'municipalityName': 'Test City',
      'isUpvotedByMe': true,
    };

void main() {
  group('IssueModel.fromJson', () {
    test('maps every field sent by the backend IssueResponse', () {
      final m = IssueModel.fromJson(_backendIssueJson());

      expect(m.trackingId, 'CC-2026-00001');
      expect(m.address, 'Main Rd');
      expect(m.upvoteCount, 1);
      expect(m.imageUrls, hasLength(2));
      expect(m.assignedTo, 'Field Worker');
      expect(m.municipalityName, 'Test City');
      expect(m.isUpvotedByMe, isTrue);
      expect(m.isOverdue, isFalse);
    });

    test('falls back to previewImageUrl when imageUrls is absent', () {
      final json = _backendIssueJson()..remove('imageUrls');
      expect(IssueModel.fromJson(json).imageUrls,
          ['https://cdn.example.com/a.jpg']);
    });

    test('handles omitted optional fields (backend uses NON_NULL)', () {
      final json = _backendIssueJson()
        ..remove('imageUrls')
        ..remove('previewImageUrl')
        ..remove('assignedTo')
        ..remove('isUpvotedByMe');
      final m = IssueModel.fromJson(json);
      expect(m.imageUrls, isEmpty);
      expect(m.assignedTo, isNull);
      expect(m.isUpvotedByMe, isFalse);
    });
  });
}
