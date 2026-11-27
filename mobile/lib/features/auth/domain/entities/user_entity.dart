import 'package:equatable/equatable.dart';

/// Immutable domain entity for an authenticated user.
///
/// Backend roles (from UserRole.java):
///   CITIZEN | FIELD_WORKER | DEPT_SUPERVISOR | MUNICIPAL_ADMIN | SYSTEM_ADMIN
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.municipalityId,
    this.departmentId,
    this.isVerified = false,
    this.isActive   = true,
  });

  final String  id;
  final String  email;
  final String  fullName;
  final String  role;
  final String? phone;
  final String? avatarUrl;
  final String? municipalityId;
  final String? departmentId;
  final bool    isVerified;
  final bool    isActive;

  // ── Role helpers ─────────────────────────────────────────────────────────
  bool get isCitizen       => role == 'CITIZEN';
  bool get isFieldWorker   => role == 'FIELD_WORKER';
  bool get isDeptSupervisor=> role == 'DEPT_SUPERVISOR';
  bool get isMunicipalAdmin=> role == 'MUNICIPAL_ADMIN';
  bool get isSystemAdmin   => role == 'SYSTEM_ADMIN';

  /// True for any authority (non-citizen) role.
  bool get isAuthority =>
      isFieldWorker || isDeptSupervisor || isMunicipalAdmin || isSystemAdmin;

  @override
  List<Object?> get props => [
        id, email, fullName, role, phone, avatarUrl,
        municipalityId, departmentId, isVerified, isActive,
      ];
}
