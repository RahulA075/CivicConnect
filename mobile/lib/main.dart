import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'firebase_options.dart';
import 'features/notifications/service/firebase_messaging_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  await _initFirebase();

  // ── Hive local database ────────────────────────────────────────────────────
  await Hive.initFlutter();
  await _registerHiveAdapters();

  // ── Device orientation ─────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Status bar styling ──────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:           Colors.transparent,
      statusBarIconBrightness:  Brightness.dark,
    ),
  );

  // Register top-level FCM background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ProviderScope(
      overrides: await buildProviderOverrides(),
      child:     const CivicConnectApp(),
    ),
  );
}

// ── Firebase initialisation ────────────────────────────────────────────────────

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Forward Flutter errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    // In unit-test or CI environments Firebase may not be configured.
    // The app continues without crash reporting / push.
    debugPrint('[Firebase] Init skipped: $e');
  }
}

Future<void> _registerHiveAdapters() async {
  // Hive type adapters registered here as they are generated.
  // Adapters will be added in Phase 5 when offline support is implemented.
}
