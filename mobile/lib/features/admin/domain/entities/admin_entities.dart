import 'package:equatable/equatable.dart';

// ── Department ────────────────────────────────────────────────────────────────

class DepartmentEntity extends Equatable {
  const DepartmentEntity({
    required this.id,
    required this.municipalityId,
    required this.name,
    this.description,
    this.iconName,
    this.colorHex,
    this.contactEmail,
    this.contactPhone,
    this.active = true,
  });

  final String  id;
  final String  municipalityId;
  final String  name;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final String? contactEmail;
  final String? contactPhone;
  final bool    active;

  @override
  List<Object?> get props => [id, name, municipalityId];
}

// ── Category ──────────────────────────────────────────────────────────────────

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.municipalityId,
    required this.departmentId,
    required this.name,
    this.departmentName,
    this.parentId,
    this.parentName,
    this.description,
    this.iconName,
    this.colorHex,
    this.sortOrder = 0,
    this.active = true,
  });

  final String  id;
  final String  municipalityId;
  final String  departmentId;
  final String  name;
  final String? departmentName;
  final String? parentId;
  final String? parentName;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final int     sortOrder;
  final bool    active;

  @override
  List<Object?> get props => [id, name];
}

// ── SLA Policy ────────────────────────────────────────────────────────────────

class SlaPolicyEntity extends Equatable {
  const SlaPolicyEntity({
    required this.id,
    required this.municipalityId,
    required this.priority,
    required this.resolutionHours,
    required this.warningHours,
    required this.escalationHours,
    this.categoryId,
    this.categoryName,
    this.active = true,
  });

  final String  id;
  final String  municipalityId;
  final String  priority;
  final int     resolutionHours;
  final int     warningHours;
  final int     escalationHours;
  final String? categoryId;
  final String? categoryName;
  final bool    active;

  @override
  List<Object?> get props => [id, priority, categoryId];
}

// ── Escalation Rule ───────────────────────────────────────────────────────────

class EscalationRuleEntity extends Equatable {
  const EscalationRuleEntity({
    required this.id,
    required this.municipalityId,
    required this.triggerAfterHours,
    required this.escalateToRole,
    this.departmentId,
    this.departmentName,
    this.notificationMessage,
    this.active = true,
  });

  final String  id;
  final String  municipalityId;
  final int     triggerAfterHours;
  final String  escalateToRole;
  final String? departmentId;
  final String? departmentName;
  final String? notificationMessage;
  final bool    active;

  @override
  List<Object?> get props => [id, triggerAfterHours, escalateToRole];
}

// ── Emergency Alert ───────────────────────────────────────────────────────────

class EmergencyAlertEntity extends Equatable {
  const EmergencyAlertEntity({
    required this.id,
    required this.municipalityId,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.targetDepartmentId,
    this.departmentName,
    this.createdByName,
    this.expiresAt,
    this.active = true,
  });

  final String    id;
  final String    municipalityId;
  final String    title;
  final String    message;
  final String    severity;
  final DateTime  createdAt;
  final String?   targetDepartmentId;
  final String?   departmentName;
  final String?   createdByName;
  final DateTime? expiresAt;
  final bool      active;

  @override
  List<Object?> get props => [id, title, createdAt];
}

// ── Audit Log ─────────────────────────────────────────────────────────────────

class AuditLogEntity extends Equatable {
  const AuditLogEntity({
    required this.id,
    required this.action,
    required this.createdAt,
    this.performedByName,
    this.entityType,
    this.entityId,
    this.detail,
    this.ipAddress,
  });

  final String    id;
  final String    action;
  final DateTime  createdAt;
  final String?   performedByName;
  final String?   entityType;
  final String?   entityId;
  final String?   detail;
  final String?   ipAddress;

  @override
  List<Object?> get props => [id, action, createdAt];
}

// ── Admin User ────────────────────────────────────────────────────────────────

class AdminUserEntity extends Equatable {
  const AdminUserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.departmentId,
    this.active = true,
  });

  final String  id;
  final String  fullName;
  final String  email;
  final String  role;
  final String? phone;
  final String? avatarUrl;
  final String? departmentId;
  final bool    active;

  @override
  List<Object?> get props => [id, email];
}
