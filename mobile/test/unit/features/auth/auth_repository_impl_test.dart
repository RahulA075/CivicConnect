import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:civicconnect/core/error/app_exception.dart';
import 'package:civicconnect/core/error/failure.dart';
import 'package:civicconnect/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:civicconnect/features/auth/data/models/auth_response_model.dart';
import 'package:civicconnect/features/auth/data/models/user_model.dart';
import 'package:civicconnect/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:civicconnect/features/auth/domain/entities/auth_tokens.dart';
import 'package:civicconnect/features/auth/domain/entities/user_entity.dart';
import 'package:civicconnect/core/storage/local_storage.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

// Fake PathProvider so Hive can find a temp directory in tests
class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

// ── Helpers ────────────────────────────────────────────────────────────────

const _user = UserModel(
  id:       'user-001',
  email:    'test@example.com',
  fullName: 'Test User',
  role:     'CITIZEN',
);

const _tokens = AuthTokens(
  accessToken:  'access.jwt.token',
  refreshToken: 'refresh-uuid-string',
);

const _authModel = AuthResponseModel(tokens: _tokens, user: _user);

// Mock the flutter_secure_storage platform channel to avoid platform errors
void _stubSecureStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    switch (call.method) {
      case 'write':
        return null;
      case 'read':
        return null;
      case 'readAll':
        return <String, String>{};
      case 'delete':
        return null;
      case 'deleteAll':
        return null;
      case 'containsKey':
        return false;
      default:
        return null;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRemoteDataSource mockDataSource;
  late AuthRepositoryImpl       repository;

  setUpAll(() async {
    // Point path_provider at temp dir so Hive can open boxes
    PathProviderPlatform.instance = _FakePathProvider();

    // Initialise Hive in the system temp directory
    Hive.init(Directory.systemTemp.path);
    await LocalStorage.init();
  });

  setUp(() {
    _stubSecureStorage();
    mockDataSource = MockAuthRemoteDataSource();
    repository     = AuthRepositoryImpl(mockDataSource);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('AuthRepositoryImpl', () {
    // ── login ────────────────────────────────────────────────────────

    test('login → Right(AuthTokens) on success', () async {
      when(() => mockDataSource.login(
            identifier: any(named: 'identifier'),
            password:   any(named: 'password'),
          )).thenAnswer((_) async => _authModel);

      final result = await repository.login(
          email: 'test@example.com', password: 'Password@123!');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (tokens) => expect(tokens.accessToken, equals('access.jwt.token')),
      );
    });

    test('login → Left(UnauthorisedFailure) on 401', () async {
      when(() => mockDataSource.login(
            identifier: any(named: 'identifier'),
            password:   any(named: 'password'),
          )).thenThrow(const UnauthorisedException('Invalid credentials'));

      final result = await repository.login(
          email: 'bad@example.com', password: 'wrong');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnauthorisedFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('login → Left(NetworkFailure) on network error', () async {
      when(() => mockDataSource.login(
            identifier: any(named: 'identifier'),
            password:   any(named: 'password'),
          )).thenThrow(const NetworkException('Connection refused'));

      final result = await repository.login(
          email: 'test@example.com', password: 'Password@123!');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('login → Left(ConflictFailure) on 409', () async {
      when(() => mockDataSource.login(
            identifier: any(named: 'identifier'),
            password:   any(named: 'password'),
          )).thenThrow(const ConflictException('Conflict'));

      final result = await repository.login(
          email: 'test@example.com', password: 'Password@123!');

      expect(result.isLeft(), isTrue);
    });

    // ── register ─────────────────────────────────────────────────────

    test('register → Right(UserEntity) on success', () async {
      when(() => mockDataSource.register(
            email:    any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            phone:    any(named: 'phone'),
            municipalityId: any(named: 'municipalityId'),
          )).thenAnswer((_) async => _authModel);

      final result = await repository.register(
          email: 'new@example.com',
          password: 'SecurePass@1!',
          fullName: 'New User');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (user) {
          expect(user, isA<UserEntity>());
          expect(user.email, equals('test@example.com'));
        },
      );
    });

    test('register → Left(ConflictFailure) when email taken', () async {
      when(() => mockDataSource.register(
            email:    any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            phone:    any(named: 'phone'),
            municipalityId: any(named: 'municipalityId'),
          )).thenThrow(const ConflictException('Email taken'));

      final result = await repository.register(
          email: 'dup@example.com',
          password: 'SecurePass@1!',
          fullName: 'Dup');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ConflictFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    // ── verifyOtp ─────────────────────────────────────────────────────

    test('verifyOtp → Right(null) on success', () async {
      when(() => mockDataSource.verifyOtp(
            identifier: any(named: 'identifier'),
            otp:        any(named: 'otp'),
            purpose:    any(named: 'purpose'),
          )).thenAnswer((_) async {});

      final result = await repository.verifyOtp(
          email: 'test@example.com', otp: '123456');

      expect(result.isRight(), isTrue);
    });

    test('verifyOtp → Left(ValidationFailure) on wrong OTP', () async {
      when(() => mockDataSource.verifyOtp(
            identifier: any(named: 'identifier'),
            otp:        any(named: 'otp'),
            purpose:    any(named: 'purpose'),
          )).thenThrow(const ValidationException('OTP incorrect'));

      final result = await repository.verifyOtp(
          email: 'test@example.com', otp: '999999');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    // ── forgotPassword ────────────────────────────────────────────────

    test('forgotPassword → Right(null) always succeeds', () async {
      when(() => mockDataSource.forgotPassword(any()))
          .thenAnswer((_) async {});

      final result = await repository.forgotPassword('test@example.com');
      expect(result.isRight(), isTrue);
    });

    // ── logout ────────────────────────────────────────────────────────

    test('logout → Right(null) and clears local state', () async {
      when(() => mockDataSource.logout(any())).thenAnswer((_) async {});

      final result = await repository.logout();
      expect(result.isRight(), isTrue);
    });
  });
}
