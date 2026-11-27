import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/auth_tokens.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, AuthTokens>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  /// [purpose]: 'REGISTRATION' | 'PASSWORD_RESET' | 'PHONE_CHANGE'
  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String otp,
    String purpose,
  });

  Future<Either<Failure, void>> forgotPassword(String email);

  Future<Either<Failure, UserEntity>> getMe();

  Future<Either<Failure, void>> logout();
}
