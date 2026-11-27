import 'package:hive_flutter/hive_flutter.dart';
import '../constants/storage_keys.dart';

/// Synchronous local key-value storage backed by Hive.
/// Must call [init()] before any read/write operations.
abstract final class LocalStorage {

  static late Box<dynamic> _settings;
  static late Box<dynamic> _auth;
  static late Box<dynamic> _cache;

  static Future<void> init() async {
    _settings = await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    _auth     = await Hive.openBox<dynamic>(StorageKeys.authBox);
    _cache    = await Hive.openBox<dynamic>(StorageKeys.cacheBox);
  }

  // ── Settings ──────────────────────────────────────────────────────

  static String? getString(String key)  => _settings.get(key) as String?;
  static bool?   getBool(String key)    => _settings.get(key) as bool?;

  static Future<void> setString(String key, String value) => _settings.put(key, value);
  static Future<void> setBool(String key, bool value)     => _settings.put(key, value);

  // ── Auth ──────────────────────────────────────────────────────────

  static String? getAuthString(String key) => _auth.get(key) as String?;
  static Future<void> setAuthString(String key, String value) => _auth.put(key, value);
  static Future<void> clearAuth() => _auth.clear();

  // ── Cache (TTL-aware entries stored as JSON strings) ──────────────

  static String? getCache(String key) => _cache.get(key) as String?;
  static Future<void> setCache(String key, String value) => _cache.put(key, value);
  static Future<void> removeCache(String key) => _cache.delete(key);
  static Future<void> clearCache() => _cache.clear();

  // ── Full clear (logout) ────────────────────────────────────────────

  static Future<void> clearAll() async {
    await clearAuth();
    await clearCache();
  }
}
