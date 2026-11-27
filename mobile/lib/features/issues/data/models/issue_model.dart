import '../../domain/entities/issue_entity.dart';

/// Maps the backend [IssueResponse] DTO.
class IssueModel extends IssueEntity {
  const IssueModel({
    required super.id,
    required super.trackingId,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    required super.categoryName,
    required super.latitude,
    required super.longitude,
    required super.address,
    required super.upvoteCount,
    required super.createdAt,
    super.categoryId,
    super.categoryColor,
    super.reporterName,
    super.assignedTo,
    super.departmentName,
    super.municipalityName,
    super.imageUrls,
    super.resolvedAt,
    super.dueDate,
    super.isUpvotedByMe,
    super.isOverdue,
    super.commentCount,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) => IssueModel(
        id:           json['id']         as String,
        trackingId:   json['trackingId'] as String,
        title:        json['title']      as String,
        description:  json['description'] as String,
        status:       (json['status']   as String?) ?? 'SUBMITTED',
        priority:     (json['priority'] as String?) ?? 'MEDIUM',
        categoryName: (json['categoryName'] as String?) ?? '',
        categoryId:   json['categoryId']    as String?,
        categoryColor:(json['categoryColor'] as String?) ?? '#1565C0',
        latitude:     (json['latitude']  as num).toDouble(),
        longitude:    (json['longitude'] as num).toDouble(),
        // Backend sends 'addressText'
        address:      (json['addressText'] as String?) ??
                      (json['address']     as String?) ?? '',
        upvoteCount:  json['upvoteCount']  as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        createdAt:    DateTime.parse(json['createdAt'] as String),
        reporterName:     json['reporterName']  as String?,
        assignedTo:       json['assignedTo']    as String?,
        departmentName:   json['departmentName'] as String?,
        municipalityName: json['municipalityName'] as String?,
        imageUrls: (json['imageUrls'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            [
              if (json['previewImageUrl'] is String)
                json['previewImageUrl'] as String,
            ],
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
        dueDate: json['slaDeadline'] != null
            ? DateTime.parse(json['slaDeadline'] as String)
            : null,
        isUpvotedByMe: json['isUpvotedByMe'] as bool? ?? false,
        isOverdue:     json['overdue']       as bool? ?? false,
      );
}
