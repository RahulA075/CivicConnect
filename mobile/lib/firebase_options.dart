// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for the civicconnect-2026 project.
/// Generated from Firebase Console credentials — do not commit credential files.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtsVhRBE8XLHmEONcmgBgqMNozW3TGBKY',
    appId: '1:1010727451423:android:84b2d8d119118e11f70e2a',
    messagingSenderId: '1010727451423',
    projectId: 'civicconnect-2026',
    storageBucket: 'civicconnect-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBhKB8JR9oRGO_HXpcSXF5RxKsTXAWN-mU',
    appId: '1:1010727451423:ios:99430d33152fa0f0f70e2a',
    messagingSenderId: '1010727451423',
    projectId: 'civicconnect-2026',
    storageBucket: 'civicconnect-2026.firebasestorage.app',
    iosBundleId: 'com.civicconnect.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDtsVhRBE8XLHmEONcmgBgqMNozW3TGBKY',
    appId: '1:1010727451423:web:0000000000000000f70e2a',
    messagingSenderId: '1010727451423',
    projectId: 'civicconnect-2026',
    storageBucket: 'civicconnect-2026.firebasestorage.app',
  );
}
