import '../../domain/entities/auth_tokens.dart';
import 'user_model.dart';

/// Maps the flat [AuthResponse] JSON returned by the backend.
///
/// Backend shape (from AuthResponse.java):
/// ```json
/// {
///   "accessToken":  "...",
///   "refreshToken": "...",
///   "tokenType":    "Bearer",
///   "expiresIn":    900,
///   "userId":       "uuid",
///   "role":         "CITIZEN",
///   "fullName":     "Jane Doe",
///   "email":        "jane@example.com",
///   "municipalityId": null,
///   "departmentId":   null
/// }
/// ```
class AuthResponseModel {
  const AuthResponseModel({required this.tokens, required this.user});

  final AuthTokens tokens;
  final UserModel  user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthResponseModel(
        tokens: AuthTokens(
          accessToken:  json['accessToken']  as String,
          refreshToken: json['refreshToken'] as String,
        ),
        user: UserModel(
          id:             json['userId'] as String,
          email:          json['email']  as String? ?? '',
          fullName:       json['fullName'] as String? ?? '',
          role:           json['role']   as String? ?? 'CITIZEN',
          municipalityId: json['municipalityId'] as String?,
          departmentId:   json['departmentId']   as String?,
          // emailVerified and isActive are not in the auth response;
          // they come from GET /users/me
          isVerified: false,
          isActive:   true,
        ),
      );
}
