import 'package:equatable/equatable.dart';

class IssueEntity extends Equatable {
  const IssueEntity({
    required this.id,
    required this.trackingId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.categoryName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.upvoteCount,
    required this.createdAt,
    this.categoryId,
    this.categoryColor = '#1565C0',
    this.reporterName,
    this.assignedTo,
    this.departmentName,
    this.municipalityName,
    this.imageUrls = const [],
    this.resolvedAt,
    this.dueDate,
    this.isUpvotedByMe = false,
    this.isOverdue     = false,
    this.commentCount  = 0,
  });

  final String   id;
  final String   trackingId;
  final String   title;
  final String   description;
  final String   status;
  final String   priority;
  final String   categoryName;
  final String?  categoryId;
  final String   categoryColor;
  final double   latitude;
  final double   longitude;
  final String   address;
  final int      upvoteCount;
  final int      commentCount;
  final DateTime createdAt;
  final String?  reporterName;
  final String?  assignedTo;
  final String?  departmentName;
  final String?  municipalityName;
  final List<String> imageUrls;
  final DateTime? resolvedAt;
  final DateTime? dueDate;
  final bool     isUpvotedByMe;
  final bool     isOverdue;

  @override
  List<Object?> get props => [
        id, trackingId, title, description, status, priority,
        categoryName, latitude, longitude, address, upvoteCount,
        createdAt, resolvedAt, dueDate, isUpvotedByMe, isOverdue,
      ];
}
