import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised before this is called.
  debugPrint('[FCM Background] ${message.messageId}: ${message.notification?.title}');
  // Show a local notification so the user sees it even when the app is killed.
  await FirebaseMessagingService._showLocalNotification(message);
}

/// Manages all Firebase Cloud Messaging lifecycle:
/// - Foreground messages  → flutter_local_notifications heads-up
/// - Background messages  → background handler + local notification
/// - Notification taps    → deep-link routing via onNotificationTap callback
/// - Token refresh        → sends new token to backend
class FirebaseMessagingService {
  FirebaseMessagingService({
    required Dio dio,
    required Logger logger,
    this.onNotificationTap,
  })  : _dio = dio,
        _log = logger;

  final Dio     _dio;
  final Logger  _log;

  /// Called when the user taps a notification.
  /// Receives the data payload (type, issueId, alertId, etc.)
  final void Function(Map<String, dynamic> data)? onNotificationTap;

  static const _channelId   = 'civicconnect_default';
  static const _channelName = 'CivicConnect Notifications';
  static const _emergencyChannelId   = 'civicconnect_emergency';
  static const _emergencyChannelName = 'Emergency Alerts';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ── Initialise ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _initLocalNotifications();
    await _requestPermissions();
    _registerBackgroundHandler();
    _listenForeground();
    _listenTaps();
    await _handleInitialMessage();
    await _refreshToken();
    _listenTokenRefresh();
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert:         true,
      announcement:  false,
      badge:         true,
      carPlay:       false,
      criticalAlert: true,
      provisional:   false,
      sound:         true,
    );
    _log.i('[FCM] Permission: ${settings.authorizationStatus}');
  }

  // ── Background handler ─────────────────────────────────────────────────────

  void _registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // ── Foreground messages ────────────────────────────────────────────────────

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log.d('[FCM Foreground] ${message.notification?.title}');
      _showLocalNotification(message);
    });
  }

  // ── Notification tap handling ─────────────────────────────────────────────

  void _listenTaps() {
    // App in background, user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log.d('[FCM Tap Background] ${message.data}');
      onNotificationTap?.call(message.data);
    });

    // Local notification tap
    _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS:     DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!) as Map<String, dynamic>;
            onNotificationTap?.call(data);
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _handleInitialMessage() async {
    // App was terminated, user tapped notification to open it
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _log.d('[FCM Initial] ${initial.data}');
      onNotificationTap?.call(initial.data);
    }
  }

  // ── Token management ───────────────────────────────────────────────────────

  Future<void> _refreshToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      _log.w('[FCM] Could not get token: $e');
    }
  }

  void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      _log.i('[FCM] Token refreshed');
      await _sendTokenToBackend(newToken);
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _dio.post<void>(
        '/api/v1/notifications/device-token',
        data: {
          'token':    token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      );
      _log.i('[FCM] Token registered with backend');
    } catch (e) {
      _log.w('[FCM] Failed to register token with backend: $e');
    }
  }

  Future<void> removeToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _dio.delete<void>(
          '/api/v1/notifications/device-token',
          data: {'token': token},
        );
        await FirebaseMessaging.instance.deleteToken();
        _log.i('[FCM] Token removed');
      }
    } catch (e) {
      _log.w('[FCM] Failed to remove token: $e');
    }
  }

  // ── Local notifications ────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // Create notification channels (Android 8+)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description:   'Issue updates and general alerts',
            importance:    Importance.high,
            enableVibration: true,
          ),
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _emergencyChannelId,
            _emergencyChannelName,
            description:   'Emergency municipal alerts',
            importance:    Importance.max,
            enableVibration: true,
            playSound:     true,
          ),
        );
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final isEmergency = message.data['type'] == 'EMERGENCY_ALERT';
    final channelId   = isEmergency ? _emergencyChannelId : _channelId;
    final channelName = isEmergency ? _emergencyChannelName : _channelName;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance:       isEmergency ? Importance.max : Importance.high,
      priority:         isEmergency ? Priority.max  : Priority.high,
      icon:             '@mipmap/ic_launcher',
      color:            isEmergency
          ? const Color(0xFFD32F2F)
          : const Color(0xFF1565C0),
      enableVibration:  true,
      playSound:        true,
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        contentTitle: notification.title,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
        android: androidDetails, iOS: iosDetails);

    final payload = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: payload,
    );
  }
}
