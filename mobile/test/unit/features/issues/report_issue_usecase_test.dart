import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:civicconnect/core/error/failure.dart';
import 'package:civicconnect/features/issues/domain/entities/issue_entity.dart';
import 'package:civicconnect/features/issues/domain/repositories/issue_repository.dart';
import 'package:civicconnect/features/issues/domain/usecases/report_issue_usecase.dart';
import 'package:civicconnect/features/issues/domain/usecases/upvote_issue_usecase.dart';
import 'package:civicconnect/features/issues/domain/usecases/get_my_issues_usecase.dart';
import 'package:civicconnect/features/issues/domain/usecases/get_public_feed_usecase.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockIssueRepository extends Mock implements IssueRepository {}

// ── Helpers ────────────────────────────────────────────────────────────────

final _issueEntity = IssueEntity(
  id:           'issue-001',
  trackingId:   'CC-2025-0001',
  title:        'Pothole on main road',
  description:  'Large pothole near bus stop',
  status:       'SUBMITTED',
  priority:     'HIGH',
  categoryName: 'Roads',
  latitude:     12.9716,
  longitude:    77.5946,
  address:      'MG Road, Bengaluru',
  upvoteCount:  0,
  createdAt:    DateTime(2025, 1, 1),
);

void main() {
  late MockIssueRepository mockRepo;

  setUp(() {
    mockRepo = MockIssueRepository();
  });

  // ── ReportIssueUseCase ─────────────────────────────────────────────────

  group('ReportIssueUseCase', () {
    late ReportIssueUseCase useCase;

    setUp(() => useCase = ReportIssueUseCase(mockRepo));

    test('call → Right(IssueEntity) on success', () async {
      when(() => mockRepo.reportIssue(
            title:       any(named: 'title'),
            description: any(named: 'description'),
            categoryId:  any(named: 'categoryId'),
            latitude:    any(named: 'latitude'),
            longitude:   any(named: 'longitude'),
            address:     any(named: 'address'),
            priority:    any(named: 'priority'),
            anonymous:   any(named: 'anonymous'),
            images:      any(named: 'images'),
          )).thenAnswer((_) async => Right(_issueEntity));

      final result = await useCase(
        title:       'Pothole on main road',
        description: 'Large pothole near bus stop',
        categoryId:  'cat-001',
        latitude:    12.9716,
        longitude:   77.5946,
        address:     'MG Road',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (issue) {
          expect(issue.trackingId, equals('CC-2025-0001'));
          expect(issue.status, equals('SUBMITTED'));
        },
      );
    });

    test('call → Left(ValidationFailure) when title is blank', () async {
      when(() => mockRepo.reportIssue(
            title:       any(named: 'title'),
            description: any(named: 'description'),
            categoryId:  any(named: 'categoryId'),
            latitude:    any(named: 'latitude'),
            longitude:   any(named: 'longitude'),
            address:     any(named: 'address'),
            priority:    any(named: 'priority'),
            anonymous:   any(named: 'anonymous'),
            images:      any(named: 'images'),
          )).thenAnswer((_) async =>
          const Left(ValidationFailure('Title is required')));

      final result = await useCase(
        title:       '',
        description: 'Description',
        categoryId:  'cat-001',
        latitude:    12.9716,
        longitude:   77.5946,
        address:     'MG Road',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('call → Left(ServerFailure) on 5xx', () async {
      when(() => mockRepo.reportIssue(
            title:       any(named: 'title'),
            description: any(named: 'description'),
            categoryId:  any(named: 'categoryId'),
            latitude:    any(named: 'latitude'),
            longitude:   any(named: 'longitude'),
            address:     any(named: 'address'),
            priority:    any(named: 'priority'),
            anonymous:   any(named: 'anonymous'),
            images:      any(named: 'images'),
          )).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase(
        title:       'Road issue',
        description: 'Description text',
        categoryId:  'cat-001',
        latitude:    12.9716,
        longitude:   77.5946,
        address:     'MG Road',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ── UpvoteIssueUseCase ─────────────────────────────────────────────────

  group('UpvoteIssueUseCase', () {
    late UpvoteIssueUseCase useCase;

    setUp(() => useCase = UpvoteIssueUseCase(mockRepo));

    test('call → Right(IssueEntity) with incremented upvote', () async {
      final upvotedIssue = IssueEntity(
        id:           'issue-001',
        trackingId:   'CC-2025-0001',
        title:        'Pothole on main road',
        description:  'Large pothole',
        status:       'SUBMITTED',
        priority:     'HIGH',
        categoryName: 'Roads',
        latitude:     12.9716,
        longitude:    77.5946,
        address:      'MG Road',
        upvoteCount:  1,
        isUpvotedByMe: true,
        createdAt:    DateTime(2025, 1, 1),
      );

      when(() => mockRepo.upvoteIssue('issue-001'))
          .thenAnswer((_) async => Right(upvotedIssue));

      final result = await useCase('issue-001');
      result.fold(
        (_) => fail('Expected Right'),
        (issue) {
          expect(issue.upvoteCount, equals(1));
          expect(issue.isUpvotedByMe, isTrue);
        },
      );
    });

    test('call → Left(ConflictFailure) when already voted', () async {
      when(() => mockRepo.upvoteIssue('issue-001'))
          .thenAnswer((_) async => const Left(ConflictFailure('Already voted')));

      final result = await useCase('issue-001');
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ConflictFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ── GetMyIssuesUseCase ─────────────────────────────────────────────────

  group('GetMyIssuesUseCase', () {
    late GetMyIssuesUseCase useCase;

    setUp(() => useCase = GetMyIssuesUseCase(mockRepo));

    test('call → Right(List<IssueEntity>) on success', () async {
      when(() => mockRepo.getMyIssues(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => Right([_issueEntity]));

      final result = await useCase();
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (issues) => expect(issues, hasLength(1)),
      );
    });

    test('call → Left(UnauthorisedFailure) when not logged in', () async {
      when(() => mockRepo.getMyIssues(
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => const Left(UnauthorisedFailure()));

      final result = await useCase();
      expect(result.isLeft(), isTrue);
    });
  });

  // ── GetPublicFeedUseCase ───────────────────────────────────────────────

  group('GetPublicFeedUseCase', () {
    late GetPublicFeedUseCase useCase;

    setUp(() => useCase = GetPublicFeedUseCase(mockRepo));

    test('call → Right(List<IssueEntity>) on success', () async {
      when(() => mockRepo.getPublicFeed(
            municipalityId: any(named: 'municipalityId'),
            page:           any(named: 'page'),
            size:           any(named: 'size'),
            categoryId:     any(named: 'categoryId'),
            status:         any(named: 'status'),
          )).thenAnswer((_) async => Right([_issueEntity, _issueEntity]));

      final result =
          await useCase(municipalityId: 'muni-001');
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (issues) => expect(issues, hasLength(2)),
      );
    });

    test('call → Left(NetworkFailure) on offline', () async {
      when(() => mockRepo.getPublicFeed(
            municipalityId: any(named: 'municipalityId'),
            page:           any(named: 'page'),
            size:           any(named: 'size'),
            categoryId:     any(named: 'categoryId'),
            status:         any(named: 'status'),
          )).thenAnswer((_) async => const Left(NoInternetFailure()));

      final result = await useCase(municipalityId: 'muni-001');
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NoInternetFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
