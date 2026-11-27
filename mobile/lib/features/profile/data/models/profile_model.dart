import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.phone,
    super.avatarUrl,
    super.bio,
    super.totalIssuesReported,
    super.totalIssuesResolved,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id:                   json['id'] as String,
        email:                json['email'] as String,
        fullName:             json['fullName'] as String,
        role:                 json['role'] as String,
        phone:                json['phone'] as String?,
        avatarUrl:            json['avatarUrl'] as String?,
        bio:                  json['bio'] as String?,
        totalIssuesReported:  json['totalIssuesReported'] as int? ?? 0,
        totalIssuesResolved:  json['totalIssuesResolved'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id':       id,
        'email':    email,
        'fullName': fullName,
        'role':     role,
        if (phone     != null) 'phone':     phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (bio       != null) 'bio':       bio,
        'totalIssuesReported': totalIssuesReported,
        'totalIssuesResolved': totalIssuesResolved,
      };
}
