/// Hive box names and key constants for local storage.
abstract final class StorageKeys {
  // ── Box names ──────────────────────────────────────────────────────
  static const String settingsBox  = 'settings';
  static const String authBox      = 'auth';
  static const String cacheBox     = 'cache';
  static const String draftsBox    = 'issue_drafts';

  // ── Auth keys ──────────────────────────────────────────────────────
  static const String accessToken   = 'access_token';
  static const String refreshToken  = 'refresh_token';
  static const String userId        = 'user_id';
  static const String userRole      = 'user_role';
  static const String municipalityId = 'municipality_id';
  static const String departmentId   = 'department_id';
  static const String isLoggedIn     = 'is_logged_in';

  // ── Settings keys ──────────────────────────────────────────────────
  static const String themeMode      = 'theme_mode';
  static const String languageCode   = 'language_code';
  static const String hasSeenOnboard = 'has_seen_onboarding';
  static const String pushEnabled    = 'push_enabled';
  static const String emailEnabled   = 'email_enabled';
}
