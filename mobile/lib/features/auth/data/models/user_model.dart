import '../../domain/entities/user_entity.dart';

/// JSON ↔ [UserEntity] mapping.
///
/// Two factory constructors:
/// - [fromAuthResponse] — maps the flat AuthResponse JWT payload
/// - [fromUserResponse] — maps GET /users/me (UserResponse shape)
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.phone,
    super.avatarUrl,
    super.municipalityId,
    super.departmentId,
    super.isVerified,
    super.isActive,
  });

  /// Maps the backend [UserResponse] DTO returned by GET /api/v1/users/me.
  /// Fields: id, fullName, email, phone, role, avatarUrl, city,
  ///         emailVerified, active, municipalityId, departmentId, createdAt
  factory UserModel.fromUserResponse(Map<String, dynamic> json) => UserModel(
        id:             json['id']       as String,
        email:          json['email']    as String? ?? '',
        fullName:       json['fullName'] as String? ?? '',
        role:           json['role']     as String? ?? 'CITIZEN',
        phone:          json['phone']    as String?,
        avatarUrl:      json['avatarUrl'] as String?,
        municipalityId: json['municipalityId'] as String?,
        departmentId:   json['departmentId']   as String?,
        isVerified:     json['emailVerified']  as bool? ?? false,
        isActive:       json['active']         as bool? ?? true,
      );

  /// Generic fromJson — same as fromUserResponse (kept for compatibility).
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromUserResponse(json);

  Map<String, dynamic> toJson() => {
        'id':       id,
        'email':    email,
        'fullName': fullName,
        'role':     role,
        if (phone          != null) 'phone':          phone,
        if (avatarUrl      != null) 'avatarUrl':      avatarUrl,
        if (municipalityId != null) 'municipalityId': municipalityId,
        if (departmentId   != null) 'departmentId':   departmentId,
        'emailVerified': isVerified,
        'active':        isActive,
      };
}
