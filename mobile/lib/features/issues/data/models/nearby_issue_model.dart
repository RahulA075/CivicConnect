import '../../domain/entities/nearby_issue_entity.dart';

class NearbyIssueModel extends NearbyIssueEntity {
  const NearbyIssueModel({
    required super.id,
    required super.trackingId,
    required super.title,
    required super.status,
    required super.latitude,
    required super.longitude,
    required super.upvoteCount,
    super.categoryName,
    super.categoryColor,
    super.addressText,
    super.priority,
    super.distanceMetres,
  });

  factory NearbyIssueModel.fromJson(Map<String, dynamic> json) =>
      NearbyIssueModel(
        id:              json['id']           as String,
        trackingId:      json['trackingId']   as String,
        title:           json['title']        as String,
        status:          (json['status'] as String?) ?? 'SUBMITTED',
        latitude:        (json['latitude']  as num).toDouble(),
        longitude:       (json['longitude'] as num).toDouble(),
        upvoteCount:     json['upvoteCount'] as int? ?? 0,
        categoryName:    (json['categoryName']  as String?) ?? '',
        categoryColor:   (json['categoryColor'] as String?) ?? '#1565C0',
        addressText:     (json['addressText']   as String?) ?? '',
        priority:        (json['priority']      as String?) ?? 'MEDIUM',
        distanceMetres:  (json['distanceMetres'] as num?)?.toDouble() ?? 0,
      );
}
