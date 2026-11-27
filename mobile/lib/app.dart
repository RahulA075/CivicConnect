import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/localization/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/notifications/service/firebase_messaging_service.dart';

/// Root widget of the CivicConnect application.
class CivicConnectApp extends ConsumerStatefulWidget {
  const CivicConnectApp({super.key});

  @override
  ConsumerState<CivicConnectApp> createState() => _CivicConnectAppState();
}

class _CivicConnectAppState extends ConsumerState<CivicConnectApp> {
  bool _fcmInitialised = false;

  @override
  void initState() {
    super.initState();
    // Check session on cold start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router    = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialise Firebase Messaging once the user is authenticated
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthAuthenticated && !_fcmInitialised) {
        _fcmInitialised = true;
        final fcm = FirebaseMessagingService(
          dio:                ref.read(dioProvider),
          logger:             ref.read(loggerProvider),
          onNotificationTap:  _handleNotificationTap,
        );
        fcm.init();
      }
      if (next is AuthUnauthenticated && _fcmInitialised) {
        // Token removal is fire-and-forget on logout — best effort
        FirebaseMessagingService(
          dio:    ref.read(dioProvider),
          logger: ref.read(loggerProvider),
        ).removeToken();
        _fcmInitialised = false;
      }
    });

    return MaterialApp.router(
      title:                    'CivicConnect',
      debugShowCheckedModeBanner: false,
      routerConfig:             router,
      theme:                    AppTheme.light(),
      darkTheme:                AppTheme.dark(),
      themeMode:                themeMode,
      locale:                   const Locale('en'),
      supportedLocales:         AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return supported.first;
        for (final s in supported) {
          if (s.languageCode == locale.languageCode) return s;
        }
        return supported.first;
      },
      // ── Global watermark ─────────────────────────────────────────────────
      // The builder wraps every route's widget tree with AppBackground, which
      // renders the Tamil Nadu Government logo as a faint centred watermark.
      // AppBar, BottomNavigationBar, Drawer, FAB, and dialogs are all
      // rendered on top automatically because they are placed in higher
      // overlay layers by Flutter's Scaffold / Navigator.
      builder: (context, child) => AppBackground(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type    = data['type']    as String?;
    final issueId = data['issueId'] as String?;

    if (issueId != null) {
      // Navigate to issue detail — router is accessible via the provider
      ref.read(appRouterProvider).push('/issues/$issueId');
    } else if (type == 'EMERGENCY_ALERT') {
      ref.read(appRouterProvider).push('/admin/alerts');
    }
  }
}
