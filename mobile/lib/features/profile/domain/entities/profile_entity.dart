import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.totalIssuesReported = 0,
    this.totalIssuesResolved = 0,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final int totalIssuesReported;
  final int totalIssuesResolved;

  @override
  List<Object?> get props => [
        id, email, fullName, role, phone, avatarUrl, bio,
        totalIssuesReported, totalIssuesResolved,
      ];
}
