import '../../domain/entities/duplicate_candidate.dart';

class DuplicateCandidateModel extends DuplicateCandidate {
  const DuplicateCandidateModel({
    required super.trackingId,
    required super.issueId,
    required super.title,
    required super.status,
    required super.latitude,
    required super.longitude,
    required super.distanceMetres,
    required super.similarityScore,
    required super.reason,
  });

  factory DuplicateCandidateModel.fromJson(Map<String, dynamic> json) =>
      DuplicateCandidateModel(
        trackingId: json['trackingId'] as String? ?? '',
        issueId: json['issueId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        distanceMetres: (json['distanceMetres'] as num?)?.toDouble() ?? 0.0,
        similarityScore: (json['similarityScore'] as num?)?.toDouble() ?? 0.0,
        reason: json['reason'] as String? ?? '',
      );
}

class DuplicateCheckResultModel extends DuplicateCheckResult {
  const DuplicateCheckResultModel({
    required super.hasPotentialDuplicates,
    required super.candidates,
  });

  factory DuplicateCheckResultModel.fromJson(Map<String, dynamic> json) {
    final candidatesJson = json['candidates'] as List<dynamic>? ?? [];
    return DuplicateCheckResultModel(
      hasPotentialDuplicates: json['hasPotentialDuplicates'] as bool? ?? false,
      candidates: candidatesJson
          .map((e) =>
              DuplicateCandidateModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
