import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/citizen/presentation/pages/bookmarks_page.dart';
import '../../features/citizen/presentation/pages/citizen_shell.dart';
import '../../features/citizen/presentation/pages/feed_page.dart';
import '../../features/citizen/presentation/pages/home_page.dart';
import '../../features/citizen/presentation/pages/issue_detail_page.dart';
import '../../features/citizen/presentation/pages/maps_page.dart';
import '../../features/citizen/presentation/pages/my_issues_page.dart';
import '../../features/citizen/presentation/pages/notifications_page.dart';
import '../../features/citizen/presentation/pages/profile_page.dart';
import '../../features/citizen/presentation/pages/report_issue_page.dart';
import '../../features/citizen/presentation/pages/settings_page.dart';
import '../../features/citizen/presentation/pages/track_complaint_page.dart';
import '../../features/officer/presentation/pages/officer_analytics_page.dart';
import '../../features/officer/presentation/pages/officer_dashboard_page.dart';
import '../../features/officer/presentation/pages/officer_issue_detail_page.dart';
import '../../features/officer/presentation/pages/officer_issues_page.dart';
import '../../features/officer/presentation/pages/officer_map_page.dart';
import '../../features/officer/presentation/pages/officer_notifications_page.dart';
import '../../features/officer/presentation/pages/officer_profile_page.dart';
import '../../features/officer/presentation/pages/officer_shell.dart';
import '../../features/admin/presentation/pages/admin_shell.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_departments_page.dart';
import '../../features/admin/presentation/pages/admin_categories_page.dart';
import '../../features/admin/presentation/pages/admin_sla_rules_page.dart';
import '../../features/admin/presentation/pages/admin_alerts_page.dart';
import '../../features/admin/presentation/pages/admin_audit_logs_page.dart';
import '../../features/ai/presentation/pages/ai_insights_page.dart';
import '../di/providers.dart';

// ── Route constants ───────────────────────────────────────────────────────────

abstract final class Routes {
  // Auth
  static const splash         = '/';
  static const login          = '/login';
  static const register       = '/register';
  static const verifyOtp      = '/verify-otp';
  static const forgotPassword = '/forgot-password';

  // ── Citizen shell ──────────────────────────────────────────────────────────
  static const home          = '/home';
  static const feed          = '/home/feed';
  static const mapsRoute     = '/home/map';
  static const notifications = '/home/notifications';
  static const profile       = '/home/profile';

  // Citizen standalone
  static const reportIssue   = '/report-issue';
  static const myIssues      = '/my-issues';
  static const bookmarks     = '/bookmarks';
  static const trackIssue    = '/track';
  static const settings      = '/settings';
  static const editProfile   = '/profile/edit';

  // AI
  static const _aiInsights = '/issues/:id/ai';
  static String aiInsightsPath(String id) => '/issues/$id/ai';
  // Dynamic citizen
  static const _issueDetail  = '/issues/:id';
  static String issueDetailPath(String id) => '/issues/$id';

  static const _trackWithId  = '/track/:trackingId';
  static const officerDashboard     = '/officer';
  static const officerIssues        = '/officer/issues';
  static const officerMap           = '/officer/map';
  static const officerAnalytics     = '/officer/analytics';
  static const officerProfile       = '/officer/profile';
  static const officerNotifications = '/officer/notifications';

  // Officer standalone
  static const _officerIssueDetail  = '/officer/issues/:id';
  static String officerIssueDetailPath(String id) => '/officer/issues/$id';

  // ── Admin shell ────────────────────────────────────────────────────────────
  static const adminDashboard   = '/admin';
  static const adminUsers       = '/admin/users';
  static const adminDepartments = '/admin/departments';
  static const adminCategories  = '/admin/categories';
  static const adminSlaRules    = '/admin/sla-rules';
  static const adminAlerts      = '/admin/alerts';
  static const adminAuditLogs   = '/admin/audit-logs';
}

// ── Router provider ───────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final isAuthRoute = _authRoutes.contains(state.matchedLocation);

      if (authState is! AuthAuthenticated) {
        return isAuthRoute ? null : Routes.login;
      }

      // authState is narrowed to AuthAuthenticated here
      final authed = authState;   // already AuthAuthenticated after is! guard

      // Redirect away from auth screens once logged in
      if (isAuthRoute && state.matchedLocation != Routes.splash) {
        if (authed.user.isMunicipalAdmin || authed.user.isSystemAdmin) {
          return Routes.adminDashboard;
        }
        return authed.user.isAuthority ? Routes.officerDashboard : Routes.home;
      }

      // Prevent non-admins from accessing admin routes
      if (state.matchedLocation.startsWith('/admin')) {
        if (!authed.user.isMunicipalAdmin && !authed.user.isSystemAdmin) {
          return authed.user.isAuthority ? Routes.officerDashboard : Routes.home;
        }
      }

      // Prevent citizens from accessing officer routes
      if (state.matchedLocation.startsWith('/officer')) {
        if (!authed.user.isAuthority) return Routes.home;
      }

      // Prevent officers/admins from accessing citizen shell routes
      if (_citizenOnlyRoutes.any((r) => state.matchedLocation.startsWith(r))) {
        if (authed.user.isAuthority) {
          return authed.user.isMunicipalAdmin || authed.user.isSystemAdmin
              ? Routes.adminDashboard
              : Routes.officerDashboard;
        }
      }

      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────────────────────
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashPage()),

      // ── Auth ────────────────────────────────────────────────────
      GoRoute(path: Routes.login,
          builder: (_, __) => const LoginPage()),
      GoRoute(path: Routes.register,
          builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: Routes.verifyOtp,
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return VerifyOtpPage(
            email:   extra['email']   ?? '',
            purpose: extra['purpose'] ?? 'REGISTRATION',
          );
        },
      ),
      GoRoute(path: Routes.forgotPassword,
          builder: (_, __) => const ForgotPasswordPage()),

      // ── Citizen shell ────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => CitizenShell(child: child),
        routes: [
          GoRoute(path: Routes.home,
              builder: (_, __) => const CitizenHomePage()),
          GoRoute(path: Routes.feed,
              builder: (_, __) => const FeedPage()),
          GoRoute(path: Routes.mapsRoute,
              builder: (_, __) => const MapsPage()),
          GoRoute(path: Routes.notifications,
              builder: (_, __) => const NotificationsPage()),
          GoRoute(path: Routes.profile,
              builder: (_, __) => const ProfilePage()),
        ],
      ),

      // ── Citizen standalone ───────────────────────────────────────
      GoRoute(path: Routes.reportIssue,
          builder: (_, __) => const ReportIssuePage()),
      GoRoute(path: Routes.myIssues,
          builder: (_, __) => const MyIssuesPage()),
      GoRoute(path: Routes.bookmarks,
          builder: (_, __) => const BookmarksPage()),
      GoRoute(path: Routes.settings,
          builder: (_, __) => const SettingsPage()),
      GoRoute(path: Routes.trackIssue,
          builder: (_, state) =>
              TrackComplaintPage(prefillId: state.extra as String?)),
      GoRoute(
        path: Routes._issueDetail,
        builder: (_, state) =>
            IssueDetailPage(issueId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes._trackWithId,
        builder: (_, state) =>
            TrackComplaintPage(prefillId: state.pathParameters['trackingId']),
      ),
      GoRoute(path: Routes.editProfile,
          builder: (_, __) =>
              const _PlaceholderPage(label: 'Edit Profile')),
      // AI insights
      GoRoute(
        path: Routes._aiInsights,
        builder: (_, state) => AiInsightsPage(
          issueId: state.pathParameters['id']!,
          trackingId: state.uri.queryParameters['trackingId'] ?? '',
        ),
      ),

      // ── Officer shell ────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => OfficerShell(child: child),
        routes: [
          GoRoute(path: Routes.officerDashboard,
              builder: (_, __) => const OfficerDashboardPage()),
          GoRoute(path: Routes.officerIssues,
              builder: (_, __) => const OfficerIssuesPage()),
          GoRoute(path: Routes.officerMap,
              builder: (_, __) => const OfficerMapPage()),
          GoRoute(path: Routes.officerAnalytics,
              builder: (_, __) => const OfficerAnalyticsPage()),
          GoRoute(path: Routes.officerProfile,
              builder: (_, __) => const OfficerProfilePage()),
        ],
      ),

      // ── Officer standalone ───────────────────────────────────────
      GoRoute(path: Routes.officerNotifications,
          builder: (_, __) => const OfficerNotificationsPage()),
      GoRoute(
        path: Routes._officerIssueDetail,
        builder: (_, state) => OfficerIssueDetailPage(
            issueId: state.pathParameters['id']!),
      ),

      // ── Admin shell ──────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: Routes.adminDashboard,
              builder: (_, __) => const AdminDashboardPage()),
          GoRoute(path: Routes.adminUsers,
              builder: (_, __) => const AdminUsersPage()),
          GoRoute(path: Routes.adminDepartments,
              builder: (_, __) => const AdminDepartmentsPage()),
          GoRoute(path: Routes.adminCategories,
              builder: (_, __) => const AdminCategoriesPage()),
          GoRoute(path: Routes.adminSlaRules,
              builder: (_, __) => const AdminSlaRulesPage()),
          GoRoute(path: Routes.adminAlerts,
              builder: (_, __) => const AdminAlertsPage()),
          GoRoute(path: Routes.adminAuditLogs,
              builder: (_, __) => const AdminAuditLogsPage()),
        ],
      ),
    ],
  );
});

// ── Auth-only routes ──────────────────────────────────────────────────────────

const _authRoutes = {
  Routes.splash,
  Routes.login,
  Routes.register,
  Routes.verifyOtp,
  Routes.forgotPassword,
};

const _citizenOnlyRoutes = [
  Routes.home,
  Routes.feed,
  Routes.mapsRoute,
  Routes.notifications,
  Routes.profile,
];

// ── Auth listenable ───────────────────────────────────────────────────────────

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (_, __) => notifyListeners());
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(label)),
        body: Center(
          child: Text('$label — coming soon',
              style: Theme.of(context).textTheme.titleMedium),
        ),
      );
}
