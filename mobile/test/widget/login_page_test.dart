import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:civicconnect/core/di/providers.dart';
import 'package:civicconnect/core/error/failure.dart';
import 'package:civicconnect/features/auth/domain/entities/auth_tokens.dart';
import 'package:civicconnect/features/auth/domain/entities/user_entity.dart';
import 'package:civicconnect/features/auth/domain/usecases/get_me_usecase.dart';
import 'package:civicconnect/features/auth/domain/usecases/login_usecase.dart';
import 'package:civicconnect/features/auth/domain/usecases/logout_usecase.dart';
import 'package:civicconnect/features/auth/domain/usecases/register_usecase.dart';
import 'package:civicconnect/features/auth/presentation/pages/login_page.dart';
import 'package:civicconnect/features/auth/presentation/providers/auth_provider.dart';
import 'package:dartz/dartz.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockLoginUseCase    extends Mock implements LoginUseCase    {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLogoutUseCase   extends Mock implements LogoutUseCase   {}
class MockGetMeUseCase    extends Mock implements GetMeUseCase    {}

// ── Helpers ────────────────────────────────────────────────────────────────

const _testUser = UserEntity(
  id:        'user-001',
  email:     'test@example.com',
  fullName:  'Test User',
  role:      'CITIZEN',
  isVerified: false,
  isActive:   true,
);

const _tokens = AuthTokens(
  accessToken:  'access.token',
  refreshToken: 'refresh.token',
);

Widget buildLoginPage({
  required MockLoginUseCase  loginMock,
  required MockGetMeUseCase  getMeMock,
}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/home',  builder: (_, __) =>
          const Scaffold(body: Text('Home'))),
    ],
  );

  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith((ref) => AuthNotifier(
            login:    loginMock,
            register: MockRegisterUseCase(),
            logout:   MockLogoutUseCase(),
            getMe:    getMeMock,
          )),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockLoginUseCase  loginMock;
  late MockGetMeUseCase  getMeMock;

  setUp(() {
    loginMock = MockLoginUseCase();
    getMeMock  = MockGetMeUseCase();
  });

  group('LoginPage widget', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildLoginPage(
          loginMock: loginMock, getMeMock: getMeMock));
      await tester.pumpAndSettle();

      expect(find.text('Email or Phone'), findsOneWidget);
      expect(find.text('Password'),       findsOneWidget);
      expect(find.text('Log In'),         findsOneWidget);
    });

    testWidgets('shows validation error when form submitted empty', (tester) async {
      await tester.pumpWidget(buildLoginPage(
          loginMock: loginMock, getMeMock: getMeMock));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log In'));
      await tester.pump();

      // Validation error should appear
      expect(find.text('Email or Phone is required'), findsOneWidget);
    });

    testWidgets('calls login use case with entered credentials', (tester) async {
      when(() => loginMock(
            email:    any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Right(_tokens));
      when(() => getMeMock())
          .thenAnswer((_) async => const Right(_testUser));

      await tester.pumpWidget(buildLoginPage(
          loginMock: loginMock, getMeMock: getMeMock));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(
          find.byType(TextFormField).last, 'Password@123!');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      verify(() => loginMock(
            email:    'test@example.com',
            password: 'Password@123!',
          )).called(1);
    });

    testWidgets('shows error banner on login failure', (tester) async {
      when(() => loginMock(
            email:    any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async =>
          const Left(UnauthorisedFailure('Invalid credentials')));

      await tester.pumpWidget(buildLoginPage(
          loginMock: loginMock, getMeMock: getMeMock));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).first, 'bad@example.com');
      await tester.enterText(
          find.byType(TextFormField).last, 'WrongPass!1');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('shows loading indicator when submitting', (tester) async {
      // Completer lets us control exactly when the login resolves
      final completer = Completer<Either<Failure, AuthTokens>>();

      when(() => loginMock(
            email:    any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildLoginPage(
          loginMock: loginMock, getMeMock: getMeMock));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(
          find.byType(TextFormField).last, 'Password@123!');
      await tester.tap(find.text('Log In'));
      await tester.pump(); // single pump — don't settle

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future so no pending timers remain
      completer.complete(const Right(_tokens));
      when(() => getMeMock())
          .thenAnswer((_) async => const Right(_testUser));
      await tester.pumpAndSettle();
    });

    testWidgets('has Forgot Password button', (tester) async {
      await tester.pumpWidget(buildLoginPage(
          loginMock: loginMock, getMeMock: getMeMock));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('has Sign Up link', (tester) async {
      await tester.pumpWidget(buildLoginPage(
          loginMock: loginMock, getMeMock: getMeMock));
      await tester.pumpAndSettle();

      expect(find.text('Sign Up'), findsOneWidget);
    });
  });
}
