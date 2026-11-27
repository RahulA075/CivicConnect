/// All backend API endpoint paths.
/// Base URL is injected at runtime from [AppConfig].
abstract final class ApiEndpoints {
  static const String _base = '/api/v1';

  // ── Auth ─────────────────────────────────────────────────────────────
  static const String register      = '$_base/auth/register';
  static const String login         = '$_base/auth/login';
  static const String refresh       = '$_base/auth/refresh';
  static const String logout        = '$_base/auth/logout';
  static const String verifyOtp     = '$_base/auth/verify-otp';
  static const String forgotPassword = '$_base/auth/forgot-password';

  // ── Users ─────────────────────────────────────────────────────────────
  static const String me     = '$_base/users/me';
  static String userById(String id) => '$_base/users/$id';

  // ── Issues (public) ────────────────────────────────────────────────
  static const String publicFeed      = '$_base/public/issues';
  static const String categories      = '$_base/public/issues/categories';
  static const String mapIssues       = '$_base/public/issues/map';
  static String trackIssue(String id) => '$_base/public/issues/track/$id';

  // ── Issues (authenticated) ─────────────────────────────────────────
  static const String issues        = '$_base/issues';
  static const String myIssues      = '$_base/issues/my';
  static const String nearbyIssues  = '$_base/issues/nearby';
  static String issueById(String id)       => '$_base/issues/$id';
  static String issueStatus(String id)     => '$_base/issues/$id/status';
  static String issueVerify(String id)     => '$_base/issues/$id/verify';
  static String issueUpvote(String id)     => '$_base/issues/$id/upvote';

  // ── Notifications ──────────────────────────────────────────────────
  static const String notifications  = '$_base/notifications';
  static const String unreadCount    = '$_base/notifications/unread-count';
  static const String markAllRead    = '$_base/notifications/read-all';
  static const String notificationPreferences = '$_base/notifications/preferences';
  static String markRead(String id)  => '$_base/notifications/$id/read';

  // ── Operations ─────────────────────────────────────────────────────
  static String departmentIssues(String deptId) => '$_base/operations/departments/$deptId/issues';
  static String departmentWorkers(String deptId) => '$_base/operations/departments/$deptId/workers';
  static String assignIssue(String id)     => '$_base/operations/issues/$id/assign';
  static String acceptIssue(String id)     => '$_base/operations/issues/$id/accept';
  static String rejectIssue(String id)     => '$_base/operations/issues/$id/reject';
  static String escalateIssue(String id)   => '$_base/operations/issues/$id/escalate';
  static String issueHistory(String id)    => '$_base/issues/$id/history';

  // ── Field worker ───────────────────────────────────────────────────
  static const String myTasks             = '$_base/field-worker/tasks';
  static String updateTaskStatus(String id) => '$_base/field-worker/tasks/$id/status';

  // ── Analytics ─────────────────────────────────────────────────────
  static String summary(String municipalityId) => '$_base/analytics/municipalities/$municipalityId/summary';
  static String heatmap(String municipalityId) => '$_base/analytics/municipalities/$municipalityId/heatmap';
  static String trend(String municipalityId)   => '$_base/analytics/municipalities/$municipalityId/trend';

  // ── Admin ──────────────────────────────────────────────────────────
  static String departments(String municipalityId) => '$_base/admin/municipalities/$municipalityId/departments';
  static String adminUsers(String municipalityId)  => '$_base/admin/municipalities/$municipalityId/users';

  // ── AI Analysis (Phase 11) ─────────────────────────────────────────
  static const String aiAnalyzeText    = '$_base/ai/analyze-text';
  static const String aiCheckDuplicate = '$_base/ai/check-duplicate';
  static const String aiSuggest        = '$_base/ai/suggest';
  static String aiIssueAnalysis(String issueId) => '$_base/ai/issues/$issueId/analysis';
  static String aiReAnalyze(String issueId)     => '$_base/ai/issues/$issueId/re-analyze';
}
