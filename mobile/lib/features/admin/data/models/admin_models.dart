import '../../domain/entities/admin_entities.dart';

// ── Department ────────────────────────────────────────────────────────────────

class DepartmentModel extends DepartmentEntity {
  const DepartmentModel({
    required super.id,
    required super.municipalityId,
    required super.name,
    super.description,
    super.iconName,
    super.colorHex,
    super.contactEmail,
    super.contactPhone,
    super.active,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> j) => DepartmentModel(
        id:             j['id']             as String,
        municipalityId: j['municipalityId'] as String,
        name:           j['name']           as String,
        description:    j['description']    as String?,
        iconName:       j['iconName']       as String?,
        colorHex:       j['colorHex']       as String?,
        contactEmail:   j['contactEmail']   as String?,
        contactPhone:   j['contactPhone']   as String?,
        active:         j['active']         as bool? ?? true,
      );
}

// ── Category ──────────────────────────────────────────────────────────────────

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.municipalityId,
    required super.departmentId,
    required super.name,
    super.departmentName,
    super.parentId,
    super.parentName,
    super.description,
    super.iconName,
    super.colorHex,
    super.sortOrder,
    super.active,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id:             j['id']             as String,
        municipalityId: j['municipalityId'] as String,
        departmentId:   j['departmentId']   as String,
        name:           j['name']           as String,
        departmentName: j['departmentName'] as String?,
        parentId:       j['parentId']       as String?,
        parentName:     j['parentName']     as String?,
        description:    j['description']    as String?,
        iconName:       j['iconName']       as String?,
        colorHex:       j['colorHex']       as String?,
        sortOrder:      j['sortOrder']      as int? ?? 0,
        active:         j['active']         as bool? ?? true,
      );
}

// ── SLA Policy ────────────────────────────────────────────────────────────────

class SlaPolicyModel extends SlaPolicyEntity {
  const SlaPolicyModel({
    required super.id,
    required super.municipalityId,
    required super.priority,
    required super.resolutionHours,
    required super.warningHours,
    required super.escalationHours,
    super.categoryId,
    super.categoryName,
    super.active,
  });

  factory SlaPolicyModel.fromJson(Map<String, dynamic> j) => SlaPolicyModel(
        id:              j['id']              as String,
        municipalityId:  j['municipalityId']  as String,
        priority:        j['priority']        as String,
        resolutionHours: j['resolutionHours'] as int,
        warningHours:    j['warningHours']    as int,
        escalationHours: j['escalationHours'] as int,
        categoryId:      j['categoryId']      as String?,
        categoryName:    j['categoryName']    as String?,
        active:          j['active']          as bool? ?? true,
      );
}

// ── Escalation Rule ───────────────────────────────────────────────────────────

class EscalationRuleModel extends EscalationRuleEntity {
  const EscalationRuleModel({
    required super.id,
    required super.municipalityId,
    required super.triggerAfterHours,
    required super.escalateToRole,
    super.departmentId,
    super.departmentName,
    super.notificationMessage,
    super.active,
  });

  factory EscalationRuleModel.fromJson(Map<String, dynamic> j) =>
      EscalationRuleModel(
        id:                  j['id']                  as String,
        municipalityId:      j['municipalityId']      as String,
        triggerAfterHours:   j['triggerAfterHours']   as int,
        escalateToRole:      j['escalateToRole']      as String,
        departmentId:        j['departmentId']        as String?,
        departmentName:      j['departmentName']      as String?,
        notificationMessage: j['notificationMessage'] as String?,
        active:              j['active']              as bool? ?? true,
      );
}

// ── Emergency Alert ───────────────────────────────────────────────────────────

class EmergencyAlertModel extends EmergencyAlertEntity {
  const EmergencyAlertModel({
    required super.id,
    required super.municipalityId,
    required super.title,
    required super.message,
    required super.severity,
    required super.createdAt,
    super.targetDepartmentId,
    super.departmentName,
    super.createdByName,
    super.expiresAt,
    super.active,
  });

  factory EmergencyAlertModel.fromJson(Map<String, dynamic> j) =>
      EmergencyAlertModel(
        id:                 j['id']                 as String,
        municipalityId:     j['municipalityId']     as String,
        title:              j['title']              as String,
        message:            j['message']            as String,
        severity:           j['severity']           as String,
        createdAt:          DateTime.parse(j['createdAt'] as String),
        targetDepartmentId: j['targetDepartmentId'] as String?,
        departmentName:     j['departmentName']     as String?,
        createdByName:      j['createdByName']      as String?,
        expiresAt: j['expiresAt'] != null
            ? DateTime.parse(j['expiresAt'] as String)
            : null,
        active: j['active'] as bool? ?? true,
      );
}

// ── Audit Log ─────────────────────────────────────────────────────────────────

class AuditLogModel extends AuditLogEntity {
  const AuditLogModel({
    required super.id,
    required super.action,
    required super.createdAt,
    super.performedByName,
    super.entityType,
    super.entityId,
    super.detail,
    super.ipAddress,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> j) => AuditLogModel(
        id:              j['id']              as String,
        action:          j['action']          as String,
        createdAt:       DateTime.parse(j['createdAt'] as String),
        performedByName: j['performedByName'] as String?,
        entityType:      j['entityType']      as String?,
        entityId:        j['entityId']        as String?,
        detail:          j['detail']          as String?,
        ipAddress:       j['ipAddress']       as String?,
      );
}

// ── Admin User ────────────────────────────────────────────────────────────────

class AdminUserModel extends AdminUserEntity {
  const AdminUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
    super.phone,
    super.avatarUrl,
    super.departmentId,
    super.active,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> j) => AdminUserModel(
        id:           j['id']           as String,
        fullName:     j['fullName']     as String,
        email:        j['email']        as String? ?? '',
        role:         j['role']         as String,
        phone:        j['phone']        as String?,
        avatarUrl:    j['avatarUrl']    as String?,
        departmentId: j['departmentId'] as String?,
        active:       j['active']       as bool? ?? true,
      );
}
