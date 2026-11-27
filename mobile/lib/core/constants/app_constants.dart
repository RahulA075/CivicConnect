/// Global application constants.
abstract final class AppConstants {
  // ── App info ────────────────────────────────────────────────────────
  static const String appName    = 'CivicConnect';
  static const String appVersion = '1.0.0';

  // ── API ─────────────────────────────────────────────────────────────
  static const String apiVersion = 'v1';
  static const int    connectTimeoutMs  = 8000;
  static const int    receiveTimeoutMs  = 10000;

  // ── Pagination ──────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize     = 50;

  // ── Issue ────────────────────────────────────────────────────────────
  static const int maxIssuePhotos   = 5;
  static const int maxPhotoSizeMb   = 10;
  static const int duplicateRadiusM = 200;

  // ── OTP ─────────────────────────────────────────────────────────────
  static const int otpLength      = 6;
  static const int otpExpiryMins  = 10;
  static const int otpResendSecs  = 45;

  // ── Map ──────────────────────────────────────────────────────────────
  static const double defaultLat  = 19.0760;   // Mumbai fallback
  static const double defaultLng  = 72.8777;
  static const double defaultZoom = 14.0;

  // ── Cache TTLs ────────────────────────────────────────────────────────
  static const Duration categoryCacheTtl   = Duration(minutes: 10);
  static const Duration dashboardCacheTtl  = Duration(seconds: 30);
  static const Duration feedCacheTtl       = Duration(minutes: 2);
}
