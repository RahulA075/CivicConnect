import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_me_usecase.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

final class AuthInitial    extends AuthState { const AuthInitial(); }
final class AuthLoading    extends AuthState { const AuthLoading(); }
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserEntity user;
}
final class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }
final class AuthError      extends AuthState {
  const AuthError(this.failure);
  final Failure failure;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required LoginUseCase    login,
    required RegisterUseCase register,
    required LogoutUseCase   logout,
    required GetMeUseCase    getMe,
  })  : _login    = login,
        _register = register,
        _logout   = logout,
        _getMe    = getMe,
        super(const AuthInitial());

  final LoginUseCase    _login;
  final RegisterUseCase _register;
  final LogoutUseCase   _logout;
  final GetMeUseCase    _getMe;

  Future<void> checkSession() async {
    // Skip API call immediately if no token stored — go straight to login
    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = const AuthUnauthenticated();
      return;
    }
    state = const AuthLoading();
    final result = await _getMe();
    result.fold(
      (failure) => state = const AuthUnauthenticated(),
      (user)    => state = AuthAuthenticated(user),
    );
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthLoading();
    final result = await _login(email: email, password: password);
    return result.fold(
      (failure) {
        state = AuthError(failure);
        return false;
      },
      (_) async {
        await checkSession();
        return true;
      },
    );
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AuthLoading();
    final result = await _register(
      email: email, password: password, fullName: fullName, phone: phone);
    return result.fold(
      (failure) {
        state = AuthError(failure);
        return false;
      },
      (user) {
        // After register, user must verify OTP; stay unauthenticated.
        state = const AuthUnauthenticated();
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _logout();
    state = const AuthUnauthenticated();
  }

  void clearError() {
    if (state is AuthError) state = const AuthUnauthenticated();
  }
}
