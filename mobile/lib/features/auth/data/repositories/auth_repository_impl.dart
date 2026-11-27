import 'package:dartz/dartz.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Either<Failure, AuthTokens>> login({
    required String email,    // 'email' kept in domain; maps to identifier
    required String password,
  }) async {
    try {
      final response =
          await _remote.login(identifier: email, password: password);
      await _persistSession(response.tokens, response.user);
      return Right(response.tokens);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _remote.register(
          email: email, password: password, fullName: fullName, phone: phone);
      // Persist tokens so app is usable before OTP verification
      await _persistSession(response.tokens, response.user);
      return Right(response.user);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String otp,
    String purpose = 'REGISTRATION',
  }) async {
    try {
      await _remote.verifyOtp(
          identifier: email, otp: otp, purpose: purpose);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(email);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getMe() async {
    try {
      final user = await _remote.getMe();
      return Right(user);
    } on AppException catch (e) {
      return Left(ErrorHandler.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _remote.logout(refreshToken);
      }
    } catch (_) {
      // best-effort — always clear local state
    } finally {
      await SecureStorage.clearTokens();
      await LocalStorage.clearAll();
    }
    return const Right(null);
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  Future<void> _persistSession(
    AuthTokens tokens,
    UserEntity user,
  ) async {
    await SecureStorage.saveTokens(
      accessToken:  tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    await LocalStorage.setAuthString(StorageKeys.userId,   user.id);
    await LocalStorage.setAuthString(StorageKeys.userRole, user.role);
    await LocalStorage.setBool(StorageKeys.isLoggedIn, true);
    if (user.municipalityId != null) {
      await LocalStorage.setAuthString(
          StorageKeys.municipalityId, user.municipalityId!);
    }
  }
}
