import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:civicconnect/core/error/failure.dart';
import 'package:civicconnect/features/auth/domain/entities/auth_tokens.dart';
import 'package:civicconnect/features/auth/domain/entities/user_entity.dart';
import 'package:civicconnect/features/auth/domain/usecases/login_usecase.dart';
import 'package:civicconnect/features/auth/domain/usecases/register_usecase.dart';
import 'package:civicconnect/features/auth/domain/usecases/logout_usecase.dart';
import 'package:civicconnect/features/auth/domain/usecases/get_me_usecase.dart';
import 'package:civicconnect/features/auth/presentation/providers/auth_provider.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockLoginUseCase    extends Mock implements LoginUseCase    {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLogoutUseCase   extends Mock implements LogoutUseCase   {}
class MockGetMeUseCase    extends Mock implements GetMeUseCase    {}

// ── Helpers ────────────────────────────────────────────────────────────────

const _testUser = UserEntity(
  id:        'user-uuid-001',
  email:     'test@example.com',
  fullName:  'Test User',
  role:      'CITIZEN',
  isVerified: false,
  isActive:   true,
);

const _tokens = AuthTokens(
  accessToken:  'access.token.here',
  refreshToken: 'refresh-token-uuid',
);

AuthNotifier _buildNotifier({
  MockLoginUseCase?    login,
  MockRegisterUseCase? register,
  MockLogoutUseCase?   logout,
  MockGetMeUseCase?    getMe,
}) =>
    AuthNotifier(
      login:    login    ?? MockLoginUseCase(),
      register: register ?? MockRegisterUseCase(),
      logout:   logout   ?? MockLogoutUseCase(),
      getMe:    getMe    ?? MockGetMeUseCase(),
      readAccessToken: () async => 'access.token.here',
    );

void main() {
  group('AuthNotifier', () {
    // ── initial state ──────────────────────────────────────────────────

    test('initial state is AuthInitial', () {
      final notifier = _buildNotifier();
      expect(notifier.state, isA<AuthInitial>());
    });

    // ── checkSession ───────────────────────────────────────────────────

    test('checkSession → AuthAuthenticated when getMe succeeds', () async {
      final getMock = MockGetMeUseCase();
      when(() => getMock()).thenAnswer((_) async => const Right(_testUser));

      final notifier = _buildNotifier(getMe: getMock);
      await notifier.checkSession();

      expect(notifier.state, isA<AuthAuthenticated>());
      expect((notifier.state as AuthAuthenticated).user, equals(_testUser));
    });

    test('checkSession → AuthUnauthenticated on failure', () async {
      final getMock = MockGetMeUseCase();
      when(() => getMock())
          .thenAnswer((_) async => const Left(UnauthorisedFailure()));

      final notifier = _buildNotifier(getMe: getMock);
      await notifier.checkSession();

      expect(notifier.state, isA<AuthUnauthenticated>());
    });

    // ── login ──────────────────────────────────────────────────────────

    test('login → returns true and transitions to AuthAuthenticated', () async {
      final loginMock = MockLoginUseCase();
      final getMock   = MockGetMeUseCase();

      when(() => loginMock(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => const Right(_tokens));
      when(() => getMock())
          .thenAnswer((_) async => const Right(_testUser));

      final notifier = _buildNotifier(login: loginMock, getMe: getMock);
      final result = await notifier.login(
          email: 'test@example.com', password: 'Password@123!');

      expect(result, isTrue);
      expect(notifier.state, isA<AuthAuthenticated>());
    });

    test('login → returns false and sets AuthError on failure', () async {
      final loginMock = MockLoginUseCase();
      when(() => loginMock(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => const Left(UnauthorisedFailure('Bad credentials')));

      final notifier = _buildNotifier(login: loginMock);
      final result = await notifier.login(
          email: 'bad@example.com', password: 'WrongPass!');

      expect(result, isFalse);
      expect(notifier.state, isA<AuthError>());
      expect((notifier.state as AuthError).failure,
          isA<UnauthorisedFailure>());
    });

    test('login → transitions through AuthLoading', () async {
      final loginMock = MockLoginUseCase();
      final getMock   = MockGetMeUseCase();

      when(() => loginMock(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => const Right(_tokens));
      when(() => getMock())
          .thenAnswer((_) async => const Right(_testUser));

      final notifier = _buildNotifier(login: loginMock, getMe: getMock);

      // Collect states
      final states = <AuthState>[];
      notifier.addListener((s) => states.add(s), fireImmediately: false);

      await notifier.login(email: 'test@example.com', password: 'Password@123!');

      expect(states.first, isA<AuthLoading>());
    });

    // ── register ───────────────────────────────────────────────────────

    test('register → returns true and sets AuthUnauthenticated (await OTP)', () async {
      final regMock = MockRegisterUseCase();
      when(() => regMock(
            email:    any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            phone:    any(named: 'phone'),
            municipalityId: any(named: 'municipalityId'),
          )).thenAnswer((_) async => const Right(_testUser));

      final notifier = _buildNotifier(register: regMock);
      final result = await notifier.register(
          email: 'new@example.com',
          password: 'SecurePass@1!',
          fullName: 'New User');

      expect(result, isTrue);
      expect(notifier.state, isA<AuthUnauthenticated>());
    });

    test('register → returns false and sets AuthError on conflict', () async {
      final regMock = MockRegisterUseCase();
      when(() => regMock(
            email:    any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            phone:    any(named: 'phone'),
            municipalityId: any(named: 'municipalityId'),
          )).thenAnswer((_) async => const Left(ConflictFailure('Email taken')));

      final notifier = _buildNotifier(register: regMock);
      final result = await notifier.register(
          email: 'dup@example.com',
          password: 'SecurePass@1!',
          fullName: 'Dup User');

      expect(result, isFalse);
      expect(notifier.state, isA<AuthError>());
    });

    // ── logout ─────────────────────────────────────────────────────────

    test('logout → sets AuthUnauthenticated', () async {
      final logoutMock = MockLogoutUseCase();
      when(() => logoutMock()).thenAnswer((_) async => const Right(null));

      final notifier = _buildNotifier(logout: logoutMock);
      await notifier.logout();

      expect(notifier.state, isA<AuthUnauthenticated>());
    });

    // ── clearError ─────────────────────────────────────────────────────

    test('clearError → resets AuthError to AuthUnauthenticated', () async {
      final loginMock = MockLoginUseCase();
      when(() => loginMock(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => const Left(UnauthorisedFailure()));

      final notifier = _buildNotifier(login: loginMock);
      await notifier.login(email: 'bad@test.com', password: 'bad');

      expect(notifier.state, isA<AuthError>());

      notifier.clearError();
      expect(notifier.state, isA<AuthUnauthenticated>());
    });
  });
}
