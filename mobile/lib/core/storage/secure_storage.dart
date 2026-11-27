import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

/// Secure key-value storage for sensitive tokens (access token, refresh token).
/// Backed by Keychain (iOS) and Android Keystore.
class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Token management ───────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken,  value: accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken()  => _storage.read(key: StorageKeys.accessToken);
  static Future<String?> getRefreshToken() => _storage.read(key: StorageKeys.refreshToken);

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
    ]);
  }

  // ── Generic ────────────────────────────────────────────────────────

  static Future<void>   write(String key, String value) => _storage.write(key: key, value: value);
  static Future<String?> read(String key)               => _storage.read(key: key);
  static Future<void>   delete(String key)              => _storage.delete(key: key);
  static Future<void>   deleteAll()                     => _storage.deleteAll();
}
