import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String identifier, // email or phone
    required String password,
  });

  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  Future<void> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  });

  Future<void> forgotPassword(String identifier);
  Future<UserModel> getMe();
  Future<void> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  // ── Login ─────────────────────────────────────────────────────────────────
  /// Backend LoginRequest uses field name `identifier` (email or phone).
  @override
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'identifier': identifier, 'password': password},
      );
      // Backend wraps response in ApiResponse envelope: { "data": { ... } }
      final data = _unwrap(resp.data!);
      return AuthResponseModel.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  @override
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'email':    email,
          'password': password,
          'fullName': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      final data = _unwrap(resp.data!);
      return AuthResponseModel.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  @override
  Future<void> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  }) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.verifyOtp,
        data: {'identifier': identifier, 'otp': otp, 'purpose': purpose},
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  /// Backend accepts identifier as a query param.
  @override
  Future<void> forgotPassword(String identifier) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.forgotPassword,
        queryParameters: {'identifier': identifier},
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Get me ────────────────────────────────────────────────────────────────
  /// Backend returns UserResponse shape (different from AuthResponse).
  @override
  Future<UserModel> getMe() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      final data = _unwrap(resp.data!);
      return UserModel.fromUserResponse(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.logout,
        data: {'refreshToken': refreshToken},
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  /// Unwraps the ApiResponse envelope: { "success": true, "data": { ... } }
  Map<String, dynamic> _unwrap(Map<String, dynamic> envelope) {
    if (envelope.containsKey('data') && envelope['data'] is Map) {
      return envelope['data'] as Map<String, dynamic>;
    }
    return envelope; // already unwrapped (e.g. direct response)
  }
}
