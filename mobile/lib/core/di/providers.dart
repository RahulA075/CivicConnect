import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../storage/local_storage.dart';
import '../theme/theme_mode_notifier.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_me_usecase.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// ── Issues ────────────────────────────────────────────────────────────────────
import '../../features/issues/data/datasources/issue_remote_datasource.dart';
import '../../features/issues/data/repositories/issue_repository_impl.dart';
import '../../features/issues/domain/repositories/issue_repository.dart';
import '../../features/issues/domain/usecases/get_public_feed_usecase.dart';
import '../../features/issues/domain/usecases/get_my_issues_usecase.dart';
import '../../features/issues/domain/usecases/report_issue_usecase.dart';
import '../../features/issues/domain/usecases/upvote_issue_usecase.dart';
import '../../features/issues/domain/usecases/get_categories_usecase.dart';
import '../../features/issues/domain/usecases/get_map_issues_usecase.dart';
import '../../features/issues/domain/entities/issue_entity.dart';
import '../../features/issues/presentation/providers/issues_provider.dart';

// ── Maps ──────────────────────────────────────────────────────────────────────
import '../../features/maps/presentation/providers/maps_provider.dart';

// ── Officer ───────────────────────────────────────────────────────────────────
import '../../features/officer/data/datasources/officer_remote_datasource.dart';
import '../../features/officer/data/repositories/officer_repository_impl.dart';
import '../../features/officer/domain/repositories/officer_repository.dart';
import '../../features/officer/domain/usecases/get_dashboard_summary_usecase.dart';
import '../../features/officer/domain/usecases/get_department_issues_usecase.dart';
import '../../features/officer/domain/usecases/get_issue_trend_usecase.dart';
import '../../features/officer/domain/usecases/officer_issue_actions_usecase.dart';
import '../../features/officer/domain/entities/analytics_entity.dart';
import '../../features/officer/presentation/providers/officer_provider.dart';

// ── Notifications ─────────────────────────────────────────────────────────────
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/entities/notification_entity.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../features/notifications/service/firebase_messaging_service.dart';

// ── Profile ───────────────────────────────────────────────────────────────────
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

// ── Admin ─────────────────────────────────────────────────────────────────────
import '../../features/admin/data/datasources/admin_remote_datasource.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/entities/admin_entities.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/domain/usecases/admin_usecases.dart';
import '../../features/admin/presentation/providers/admin_provider.dart';

// ── AI Analysis (Phase 11) ────────────────────────────────────────────────────
import '../../features/ai/data/datasources/ai_remote_datasource.dart';
import '../../features/ai/data/repositories/ai_repository_impl.dart';
import '../../features/ai/domain/repositories/ai_repository.dart';
import '../../features/ai/domain/usecases/analyze_issue_text.dart';
import '../../features/ai/domain/usecases/check_duplicate.dart';
import '../../features/ai/domain/usecases/get_smart_suggestions.dart';
import '../../features/ai/presentation/providers/ai_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Infrastructure
// ─────────────────────────────────────────────────────────────────────────────

final appConfigProvider = Provider<AppConfig>((_) => AppConfig.dev());

final loggerProvider = Provider<Logger>((_) => Logger(
      printer: PrettyPrinter(methodCount: 0, colors: true, printEmojis: true),
    ));

final dioProvider = Provider<Dio>((ref) => DioClient.create(
      config: ref.watch(appConfigProvider),
      logger: ref.watch(loggerProvider),
    ));

final connectivityProvider = Provider<Connectivity>((_) => Connectivity());

final networkInfoProvider = Provider<NetworkInfo>(
    (ref) => NetworkInfo(ref.watch(connectivityProvider)));

// ─────────────────────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────────────────────

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Auth
// ─────────────────────────────────────────────────────────────────────────────

final authRemoteDsProvider = Provider<AuthRemoteDataSource>(
    (ref) => AuthRemoteDataSourceImpl(ref.watch(dioProvider)));

final municipalitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => ref.watch(authRemoteDsProvider).getMunicipalities());

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepositoryImpl(ref.watch(authRemoteDsProvider)));

final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));
final registerUseCaseProvider =
    Provider((ref) => RegisterUseCase(ref.watch(authRepositoryProvider)));
final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));
final getMeUseCaseProvider =
    Provider((ref) => GetMeUseCase(ref.watch(authRepositoryProvider)));

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(
          login:    ref.watch(loginUseCaseProvider),
          register: ref.watch(registerUseCaseProvider),
          logout:   ref.watch(logoutUseCaseProvider),
          getMe:    ref.watch(getMeUseCaseProvider),
        ));

// ─────────────────────────────────────────────────────────────────────────────
// Issues
// ─────────────────────────────────────────────────────────────────────────────

final issueRemoteDsProvider = Provider<IssueRemoteDataSource>(
    (ref) => IssueRemoteDataSourceImpl(ref.watch(dioProvider)));

final issueRepositoryProvider = Provider<IssueRepository>(
    (ref) => IssueRepositoryImpl(ref.watch(issueRemoteDsProvider)));

final getPublicFeedUseCaseProvider =
    Provider((ref) => GetPublicFeedUseCase(ref.watch(issueRepositoryProvider)));
final getMyIssuesUseCaseProvider =
    Provider((ref) => GetMyIssuesUseCase(ref.watch(issueRepositoryProvider)));
final reportIssueUseCaseProvider =
    Provider((ref) => ReportIssueUseCase(ref.watch(issueRepositoryProvider)));
final upvoteIssueUseCaseProvider =
    Provider((ref) => UpvoteIssueUseCase(ref.watch(issueRepositoryProvider)));
final getCategoriesUseCaseProvider =
    Provider((ref) => GetCategoriesUseCase(ref.watch(issueRepositoryProvider)));
final getMapIssuesUseCaseProvider =
    Provider((ref) => GetMapIssuesUseCase(ref.watch(issueRepositoryProvider)));

final feedNotifierProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<IssueEntity>>>(
        (ref) => FeedNotifier(ref.watch(getPublicFeedUseCaseProvider)));

final myIssuesNotifierProvider =
    StateNotifierProvider<MyIssuesNotifier, AsyncValue<List<IssueEntity>>>(
        (ref) => MyIssuesNotifier(ref.watch(getMyIssuesUseCaseProvider)));

final reportIssueNotifierProvider =
    StateNotifierProvider<ReportIssueNotifier, ReportIssueState>(
        (ref) => ReportIssueNotifier(ref.watch(reportIssueUseCaseProvider)));

final upvoteNotifierProvider =
    StateNotifierProvider.autoDispose<UpvoteNotifier, AsyncValue<void>>(
        (ref) => UpvoteNotifier(ref.watch(upvoteIssueUseCaseProvider)));

final bookmarkNotifierProvider =
    StateNotifierProvider<BookmarkNotifier, Set<String>>(
        (_) => BookmarkNotifier());

final categoriesNotifierProvider = StateNotifierProvider<CategoriesNotifier,
    AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => CategoriesNotifier(
    ref.watch(getCategoriesUseCaseProvider),
  ),
);

// ── Maps ──────────────────────────────────────────────────────────────────────

final mapNotifierProvider =
    StateNotifierProvider<MapNotifier, MapState>(
        (ref) => MapNotifier(ref.watch(getMapIssuesUseCaseProvider)));

// ─────────────────────────────────────────────────────────────────────────────
// Officer
// ─────────────────────────────────────────────────────────────────────────────

final officerRemoteDsProvider = Provider<OfficerRemoteDataSource>(
    (ref) => OfficerRemoteDataSourceImpl(ref.watch(dioProvider)));

final officerRepositoryProvider = Provider<OfficerRepository>(
    (ref) => OfficerRepositoryImpl(ref.watch(officerRemoteDsProvider)));

final getDeptIssuesUseCaseProvider =
    Provider((ref) => GetDepartmentIssuesUseCase(ref.watch(officerRepositoryProvider)));
final getDashboardSummaryUseCaseProvider =
    Provider((ref) => GetDashboardSummaryUseCase(ref.watch(officerRepositoryProvider)));
final getIssueTrendUseCaseProvider =
    Provider((ref) => GetIssueTrendUseCase(ref.watch(officerRepositoryProvider)));
final officerActionsUseCaseProvider =
    Provider((ref) => OfficerIssueActionsUseCase(ref.watch(officerRepositoryProvider)));

final deptIssuesNotifierProvider =
    StateNotifierProvider<DeptIssuesNotifier, AsyncValue<List<IssueEntity>>>(
        (ref) => DeptIssuesNotifier(ref.watch(getDeptIssuesUseCaseProvider)));

final officerActionsNotifierProvider =
    StateNotifierProvider.autoDispose<OfficerActionsNotifier, OfficerActionState>(
        (ref) => OfficerActionsNotifier(ref.watch(officerActionsUseCaseProvider)));

final timelineNotifierProvider =
    StateNotifierProvider.autoDispose<TimelineNotifier, AsyncValue<List<StatusHistoryEntity>>>(
        (ref) => TimelineNotifier(ref.watch(officerActionsUseCaseProvider)));

final workersNotifierProvider =
    StateNotifierProvider.autoDispose<WorkersNotifier, AsyncValue<List<WorkerEntity>>>(
        (ref) => WorkersNotifier(ref.watch(officerActionsUseCaseProvider)));

final analyticsNotifierProvider =
    StateNotifierProvider<AnalyticsNotifier, AsyncValue<DashboardSummaryEntity>>(
        (ref) => AnalyticsNotifier(
              ref.watch(getDashboardSummaryUseCaseProvider),
              ref.watch(getIssueTrendUseCaseProvider),
            ));

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────

final notificationRemoteDsProvider = Provider<NotificationRemoteDataSource>(
    (ref) => NotificationRemoteDataSourceImpl(ref.watch(dioProvider)));

final notificationRepositoryProvider = Provider<NotificationRepository>(
    (ref) =>
        NotificationRepositoryImpl(ref.watch(notificationRemoteDsProvider)));

// ── Use cases ─────────────────────────────────────────────────────────────────
final _getNotifUCProvider  = Provider((ref) =>
    GetNotificationsUseCase(ref.watch(notificationRepositoryProvider)));
final _markReadUCProvider  = Provider((ref) =>
    MarkReadUseCase(ref.watch(notificationRepositoryProvider)));
final _markAllReadUCProvider = Provider((ref) =>
    MarkAllReadUseCase(ref.watch(notificationRepositoryProvider)));
final _getNotifPrefsUCProvider = Provider((ref) =>
    GetNotificationPrefsUseCase(ref.watch(notificationRepositoryProvider)));
final _updateNotifPrefsUCProvider = Provider((ref) =>
    UpdateNotificationPrefsUseCase(ref.watch(notificationRepositoryProvider)));

// ── Notifiers ─────────────────────────────────────────────────────────────────

final _getUnreadCountUCProvider = Provider((ref) =>
    GetUnreadCountUseCase(ref.watch(notificationRepositoryProvider)));

final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, int>((ref) =>
        UnreadCountNotifier(ref.watch(_getUnreadCountUCProvider)));

final notificationsNotifierProvider = StateNotifierProvider<
    NotificationsNotifier, AsyncValue<List<NotificationEntity>>>(
  (ref) => NotificationsNotifier(
    getNotifications: ref.watch(_getNotifUCProvider),
    markReadUC:       ref.watch(_markReadUCProvider),
    markAllReadUC:    ref.watch(_markAllReadUCProvider),
  ),
);

final notificationPrefsProvider = StateNotifierProvider<
    NotificationPrefsNotifier,
    AsyncValue<NotificationPreferencesEntity>>(
  (ref) => NotificationPrefsNotifier(
    ref.watch(_getNotifPrefsUCProvider),
    ref.watch(_updateNotifPrefsUCProvider),
  ),
);

// ── Firebase Messaging Service ────────────────────────────────────────────────
final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>(
  (ref) => FirebaseMessagingService(
    dio:    ref.watch(dioProvider),
    logger: ref.watch(loggerProvider),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Profile
// ─────────────────────────────────────────────────────────────────────────────

final profileRemoteDsProvider = Provider<ProfileRemoteDataSource>(
    (ref) => ProfileRemoteDataSourceImpl(ref.watch(dioProvider)));

final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDsProvider)));

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
        (ref) => ProfileNotifier(ref.watch(profileRepositoryProvider)));

// ─────────────────────────────────────────────────────────────────────────────
// Bootstrap
// ─────────────────────────────────────────────────────────────────────────────

Future<List<Override>> buildProviderOverrides() async {
  await LocalStorage.init();
  final config = await AppConfig.devAsync();
  return [appConfigProvider.overrideWithValue(config)];
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin
// ─────────────────────────────────────────────────────────────────────────────

final adminRemoteDsProvider = Provider<AdminRemoteDataSource>(
    (ref) => AdminRemoteDataSourceImpl(ref.watch(dioProvider)));

final adminRepositoryProvider = Provider<AdminRepository>(
    (ref) => AdminRepositoryImpl(ref.watch(adminRemoteDsProvider)));

// ── Use cases ─────────────────────────────────────────────────────────────────
final _getDepartsUCProvider   = Provider((ref) => GetDepartmentsUseCase(ref.watch(adminRepositoryProvider)));
final _createDeptUCProvider   = Provider((ref) => CreateDepartmentUseCase(ref.watch(adminRepositoryProvider)));
final _updateDeptUCProvider   = Provider((ref) => UpdateDepartmentUseCase(ref.watch(adminRepositoryProvider)));
final _deactivateDeptUCProvider = Provider((ref) => DeactivateDepartmentUseCase(ref.watch(adminRepositoryProvider)));

final _getCatsUCProvider      = Provider((ref) => GetCategoriesAdminUseCase(ref.watch(adminRepositoryProvider)));
final _createCatUCProvider    = Provider((ref) => CreateCategoryUseCase(ref.watch(adminRepositoryProvider)));
final _updateCatUCProvider    = Provider((ref) => UpdateCategoryUseCase(ref.watch(adminRepositoryProvider)));

final _getSlaUCProvider       = Provider((ref) => GetSlaPoliciesUseCase(ref.watch(adminRepositoryProvider)));
final _createSlaUCProvider    = Provider((ref) => CreateSlaPolicyUseCase(ref.watch(adminRepositoryProvider)));
final _updateSlaUCProvider    = Provider((ref) => UpdateSlaPolicyUseCase(ref.watch(adminRepositoryProvider)));

final _getEscUCProvider       = Provider((ref) => GetEscalationRulesUseCase(ref.watch(adminRepositoryProvider)));
final _createEscUCProvider    = Provider((ref) => CreateEscalationRuleUseCase(ref.watch(adminRepositoryProvider)));
final _updateEscUCProvider    = Provider((ref) => UpdateEscalationRuleUseCase(ref.watch(adminRepositoryProvider)));

final _getAdminUsersUCProvider = Provider((ref) => GetAdminUsersUseCase(ref.watch(adminRepositoryProvider)));
final _inviteUserUCProvider    = Provider((ref) => InviteUserUseCase(ref.watch(adminRepositoryProvider)));
final _userActionsUCProvider   = Provider((ref) => AdminUserActionsUseCase(ref.watch(adminRepositoryProvider)));

final _getAlertsUCProvider    = Provider((ref) => GetAlertsUseCase(ref.watch(adminRepositoryProvider)));
final _createAlertUCProvider  = Provider((ref) => CreateAlertUseCase(ref.watch(adminRepositoryProvider)));

final _getAuditLogsUCProvider = Provider((ref) => GetAuditLogsUseCase(ref.watch(adminRepositoryProvider)));

// ── Notifiers ─────────────────────────────────────────────────────────────────

final adminDepartmentsProvider =
    StateNotifierProvider<DepartmentsNotifier, AsyncValue<List<DepartmentEntity>>>(
        (ref) => DepartmentsNotifier(
              ref.watch(_getDepartsUCProvider),
              ref.watch(_createDeptUCProvider),
              ref.watch(_updateDeptUCProvider),
              ref.watch(_deactivateDeptUCProvider),
            ));

final adminCategoriesProvider =
    StateNotifierProvider<CategoriesAdminNotifier, AsyncValue<List<CategoryEntity>>>(
        (ref) => CategoriesAdminNotifier(
              ref.watch(_getCatsUCProvider),
              ref.watch(_createCatUCProvider),
              ref.watch(_updateCatUCProvider),
            ));

final adminSlaPoliciesProvider =
    StateNotifierProvider<SlaPoliciesNotifier, AsyncValue<List<SlaPolicyEntity>>>(
        (ref) {
          final repo = ref.watch(adminRepositoryProvider);
          return SlaPoliciesNotifier(
            ref.watch(_getSlaUCProvider),
            ref.watch(_createSlaUCProvider),
            ref.watch(_updateSlaUCProvider),
            (id) => repo.deactivateSlaPolicy(id),
          );
        });

final adminEscalationRulesProvider =
    StateNotifierProvider<EscalationRulesNotifier, AsyncValue<List<EscalationRuleEntity>>>(
        (ref) {
          final repo = ref.watch(adminRepositoryProvider);
          return EscalationRulesNotifier(
            ref.watch(_getEscUCProvider),
            ref.watch(_createEscUCProvider),
            ref.watch(_updateEscUCProvider),
            (id) => repo.deactivateEscalationRule(id),
          );
        });

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AsyncValue<List<AdminUserEntity>>>(
        (ref) => AdminUsersNotifier(
              ref.watch(_getAdminUsersUCProvider),
              ref.watch(_inviteUserUCProvider),
              ref.watch(_userActionsUCProvider),
            ));

final adminAlertsProvider =
    StateNotifierProvider<EmergencyAlertsNotifier, AsyncValue<List<EmergencyAlertEntity>>>(
        (ref) => EmergencyAlertsNotifier(
              ref.watch(_getAlertsUCProvider),
              ref.watch(_createAlertUCProvider),
            ));

final adminAuditLogsProvider =
    StateNotifierProvider<AuditLogsNotifier, AsyncValue<List<AuditLogEntity>>>(
        (ref) => AuditLogsNotifier(ref.watch(_getAuditLogsUCProvider)));

// ─────────────────────────────────────────────────────────────────────────────
// AI Analysis (Phase 11)
// ─────────────────────────────────────────────────────────────────────────────

final aiRemoteDsProvider = Provider<AiRemoteDataSource>(
    (ref) => AiRemoteDataSourceImpl(ref.watch(dioProvider)));

final aiRepositoryProvider = Provider<AiRepository>(
    (ref) => AiRepositoryImpl(ref.watch(aiRemoteDsProvider)));

final analyzeIssueTextUCProvider =
    Provider((ref) => AnalyzeIssueText(ref.watch(aiRepositoryProvider)));

final checkDuplicateUCProvider =
    Provider((ref) => CheckDuplicate(ref.watch(aiRepositoryProvider)));

final getSmartSuggestionsUCProvider =
    Provider((ref) => GetSmartSuggestions(ref.watch(aiRepositoryProvider)));

/// Stateful notifier for issue-composition AI analysis (used on submit form).
final aiAnalysisNotifierProvider =
    StateNotifierProvider.autoDispose<AiAnalysisNotifier, AiAnalysisState>(
        (ref) => AiAnalysisNotifier(
              analyzeText:       ref.watch(analyzeIssueTextUCProvider),
              checkDuplicate:    ref.watch(checkDuplicateUCProvider),
              getSmartSuggestions: ref.watch(getSmartSuggestionsUCProvider),
            ));

/// Provider to load a stored analysis for an already-submitted issue.
final issueAnalysisProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, issueId) async {
  final repo = ref.watch(aiRepositoryProvider);
  final result = await repo.getAnalysisForIssue(issueId);
  return result.fold((_) => null, (r) => r);
});
