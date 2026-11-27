import 'package:equatable/equatable.dart';

/// Lightweight entity returned by the public map endpoint.
/// Contains only what is needed to render a map marker.
class NearbyIssueEntity extends Equatable {
  const NearbyIssueEntity({
    required this.id,
    required this.trackingId,
    required this.title,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.upvoteCount,
    this.categoryName  = '',
    this.categoryColor = '#1565C0',
    this.addressText   = '',
    this.priority      = 'MEDIUM',
    this.distanceMetres = 0,
  });

  final String id;
  final String trackingId;
  final String title;
  final String status;
  final double latitude;
  final double longitude;
  final int    upvoteCount;
  final String categoryName;
  final String categoryColor;
  final String addressText;
  final String priority;
  final double distanceMetres;

  @override
  List<Object?> get props => [id, trackingId, status, latitude, longitude];
}
