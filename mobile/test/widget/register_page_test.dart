import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:civicconnect/core/di/providers.dart';
import 'package:civicconnect/core/router/app_router.dart';
import 'package:civicconnect/features/auth/domain/entities/user_entity.dart';
import 'package:civicconnect/features/auth/domain/usecases/get_me_usecase.dart';
import 'package:civicconnect/features/auth/domain/usecases/login_usecase.dart';
import 'package:civicconnect/features/auth/domain/usecases/logout_usecase.dart';
import 'package:civicconnect/features/auth/domain/usecases/register_usecase.dart';
import 'package:civicconnect/features/auth/presentation/pages/register_page.dart';
import 'package:civicconnect/features/auth/presentation/providers/auth_provider.dart';
import 'package:civicconnect/shared/widgets/app_button.dart';

class MockLoginUseCase    extends Mock implements LoginUseCase    {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLogoutUseCase   extends Mock implements LogoutUseCase   {}
class MockGetMeUseCase    extends Mock implements GetMeUseCase    {}

const _user = UserEntity(
  id: 'user-001',
  email: 'new@example.com',
  fullName: 'New User',
  role: 'CITIZEN',
  isVerified: false,
  isActive: true,
);

Widget _buildPage(MockRegisterUseCase registerMock,
    {Future<List<Map<String, dynamic>>> Function()? loadMunicipalities}) {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: Routes.verifyOtp,
          builder: (_, __) => const Scaffold(body: Text('Verify OTP'))),
    ],
  );
  return ProviderScope(
    overrides: [
      municipalitiesProvider.overrideWith((ref) =>
          loadMunicipalities?.call() ??
          Future.value([
            {'id': 'muni-1', 'name': 'Test City', 'state': 'TN'},
          ])),
      authNotifierProvider.overrideWith((ref) => AuthNotifier(
            login: MockLoginUseCase(),
            register: registerMock,
            logout: MockLogoutUseCase(),
            getMe: MockGetMeUseCase(),
            readAccessToken: () async => null,
          )),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('sends the selected municipality when registering',
      (tester) async {
    final registerMock = MockRegisterUseCase();
    when(() => registerMock(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          municipalityId: any(named: 'municipalityId'),
        )).thenAnswer((_) async => const Right(_user));

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildPage(registerMock));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'New User');
    await tester.enterText(fields.at(1), 'new@example.com');
    await tester.enterText(fields.at(3), 'SecurePass@1!');
    await tester.enterText(fields.at(4), 'SecurePass@1!');

    await tester.tap(find.widgetWithText(AppButton, 'Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('Select your municipality'), findsOneWidget);
    verifyNever(() => registerMock(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          municipalityId: any(named: 'municipalityId'),
        ));

    await tester.tap(find.byKey(const Key('municipalityField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test City, TN').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Create Account'));
    await tester.pumpAndSettle();

    verify(() => registerMock(
          email: 'new@example.com',
          password: 'SecurePass@1!',
          fullName: 'New User',
          phone: null,
          municipalityId: 'muni-1',
        )).called(1);
  });

  testWidgets('does not register while municipalities failed to load',
      (tester) async {
    final registerMock = MockRegisterUseCase();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildPage(registerMock,
        loadMunicipalities: () => Future.error(Exception('offline'))));
    await tester.pumpAndSettle();
    expect(find.text('Could not load municipalities'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'New User');
    await tester.enterText(fields.at(1), 'new@example.com');
    await tester.enterText(fields.at(3), 'SecurePass@1!');
    await tester.enterText(fields.at(4), 'SecurePass@1!');
    await tester.tap(find.widgetWithText(AppButton, 'Create Account'));
    await tester.pumpAndSettle();

    verifyNever(() => registerMock(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          municipalityId: any(named: 'municipalityId'),
        ));
  });
}
