import '../../domain/entities/analytics_entity.dart';

class DashboardSummaryModel extends DashboardSummaryEntity {
  const DashboardSummaryModel({
    super.totalOpen,
    super.totalInProgress,
    super.totalResolved,
    super.totalOverdue,
    super.totalClosed,
    super.avgCitizenRating,
    super.departmentStats,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> j) =>
      DashboardSummaryModel(
        totalOpen:         j['totalOpen']         as int? ?? 0,
        totalInProgress:   j['totalInProgress']   as int? ?? 0,
        totalResolved:     j['totalResolved']      as int? ?? 0,
        totalOverdue:      j['totalOverdue']       as int? ?? 0,
        totalClosed:       j['totalClosed']        as int? ?? 0,
        avgCitizenRating: (j['avgCitizenRating']  as num?)?.toDouble() ?? 0,
        departmentStats: (j['departmentStats'] as List<dynamic>? ?? [])
            .map((e) => DeptStatModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DeptStatModel extends DeptStatEntity {
  const DeptStatModel({
    required super.departmentName,
    super.openCount,
    super.overdueCount,
    super.slaCompliancePct,
    super.avgResolutionHours,
  });

  factory DeptStatModel.fromJson(Map<String, dynamic> j) => DeptStatModel(
        departmentName:     j['departmentName']      as String? ?? '',
        openCount:          j['openCount']           as int?    ?? 0,
        overdueCount:       j['overdueCount']        as int?    ?? 0,
        slaCompliancePct:  (j['slaCompliancePct']   as num?)?.toDouble() ?? 100,
        avgResolutionHours:(j['avgResolutionHours'] as num?)?.toDouble() ?? 0,
      );
}

class TrendPointModel extends TrendPointEntity {
  const TrendPointModel({
    required super.day,
    super.submitted,
    super.resolved,
    super.overdueCount,
  });

  factory TrendPointModel.fromJson(Map<String, dynamic> j) => TrendPointModel(
        day:          DateTime.parse(j['day'] as String),
        submitted:    j['submitted']    as int? ?? 0,
        resolved:     j['resolved']     as int? ?? 0,
        overdueCount: j['overdueCount'] as int? ?? 0,
      );
}

class StatusHistoryModel extends StatusHistoryEntity {
  const StatusHistoryModel({
    required super.id,
    required super.newStatus,
    required super.createdAt,
    super.oldStatus,
    super.changedByName,
    super.changedByRole,
    super.note,
  });

  factory StatusHistoryModel.fromJson(Map<String, dynamic> j) => StatusHistoryModel(
        id:            j['id']           as String,
        newStatus:     (j['newStatus'] as String?) ?? '',
        oldStatus:     j['oldStatus']    as String?,
        changedByName: j['changedByName'] as String?,
        changedByRole: j['changedByRole'] as String?,
        note:          j['note']         as String?,
        createdAt:     DateTime.parse(j['createdAt'] as String),
      );
}

class WorkerModel extends WorkerEntity {
  const WorkerModel({
    required super.id,
    required super.fullName,
    super.email,
    super.role,
    super.avatarUrl,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> j) => WorkerModel(
        id:        j['id']        as String,
        fullName:  j['fullName']  as String,
        email:     j['email']     as String?,
        role:      j['role']      as String?,
        avatarUrl: j['avatarUrl'] as String?,
      );
}
