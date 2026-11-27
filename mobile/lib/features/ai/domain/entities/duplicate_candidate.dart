import 'package:equatable/equatable.dart';

/// A nearby issue that may be a duplicate of the one being submitted.
class DuplicateCandidate extends Equatable {
  final String trackingId;
  final String issueId;
  final String title;
  final String status;
  final double latitude;
  final double longitude;
  final double distanceMetres;
  final double similarityScore;
  final String reason;

  const DuplicateCandidate({
    required this.trackingId,
    required this.issueId,
    required this.title,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.distanceMetres,
    required this.similarityScore,
    required this.reason,
  });

  @override
  List<Object?> get props => [trackingId, issueId, similarityScore];
}

/// Result of a duplicate check.
class DuplicateCheckResult extends Equatable {
  final bool hasPotentialDuplicates;
  final List<DuplicateCandidate> candidates;

  const DuplicateCheckResult({
    required this.hasPotentialDuplicates,
    required this.candidates,
  });

  static const empty = DuplicateCheckResult(
    hasPotentialDuplicates: false,
    candidates: [],
  );

  @override
  List<Object?> get props => [hasPotentialDuplicates, candidates];
}
