import 'package:equatable/equatable.dart';

class DashboardSummaryEntity extends Equatable {
  const DashboardSummaryEntity({
    this.totalOpen       = 0,
    this.totalInProgress = 0,
    this.totalResolved   = 0,
    this.totalOverdue    = 0,
    this.totalClosed     = 0,
    this.avgCitizenRating = 0,
    this.departmentStats = const [],
  });

  final int    totalOpen;
  final int    totalInProgress;
  final int    totalResolved;
  final int    totalOverdue;
  final int    totalClosed;
  final double avgCitizenRating;
  final List<DeptStatEntity> departmentStats;

  @override
  List<Object?> get props => [totalOpen, totalInProgress, totalResolved,
      totalOverdue, totalClosed, avgCitizenRating];
}

class DeptStatEntity extends Equatable {
  const DeptStatEntity({
    required this.departmentName,
    this.openCount        = 0,
    this.overdueCount     = 0,
    this.slaCompliancePct = 100,
    this.avgResolutionHours = 0,
  });

  final String departmentName;
  final int    openCount;
  final int    overdueCount;
  final double slaCompliancePct;
  final double avgResolutionHours;

  @override
  List<Object?> get props => [departmentName, openCount, overdueCount];
}

class TrendPointEntity extends Equatable {
  const TrendPointEntity({
    required this.day,
    this.submitted    = 0,
    this.resolved     = 0,
    this.overdueCount = 0,
  });

  final DateTime day;
  final int      submitted;
  final int      resolved;
  final int      overdueCount;

  @override
  List<Object?> get props => [day, submitted, resolved];
}

class StatusHistoryEntity extends Equatable {
  const StatusHistoryEntity({
    required this.id,
    required this.newStatus,
    required this.createdAt,
    this.oldStatus,
    this.changedByName,
    this.changedByRole,
    this.note,
  });

  final String   id;
  final String   newStatus;
  final DateTime createdAt;
  final String?  oldStatus;
  final String?  changedByName;
  final String?  changedByRole;
  final String?  note;

  @override
  List<Object?> get props => [id, newStatus, createdAt];
}

class WorkerEntity extends Equatable {
  const WorkerEntity({
    required this.id,
    required this.fullName,
    this.email,
    this.role,
    this.avatarUrl,
  });

  final String  id;
  final String  fullName;
  final String? email;
  final String? role;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, fullName];
}
