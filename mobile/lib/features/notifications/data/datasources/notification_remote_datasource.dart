import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/error_handler.dart';
import '../models/notification_model.dart';

abstract interface class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({int page, int size});
  Future<int>  getUnreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<NotificationPreferencesModel> getPreferences();
  Future<NotificationPreferencesModel> updatePreferences(
      NotificationPreferencesModel prefs);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  dynamic _data(Map<String, dynamic> envelope) =>
      envelope.containsKey('data') ? envelope['data'] : envelope;

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'size': size},
      );
      final paged = _data(resp.data!) as Map<String, dynamic>;
      final list  = paged['content'] as List<dynamic>? ?? [];
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.unreadCount);
      final data = _data(resp.data!) as Map<String, dynamic>;
      return data['unreadCount'] as int? ?? 0;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.patch<void>(ApiEndpoints.markRead(id));
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.post<void>(ApiEndpoints.markAllRead);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.notificationPreferences);
      return NotificationPreferencesModel.fromJson(
          _data(resp.data!) as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
      NotificationPreferencesModel prefs) async {
    try {
      final resp = await _dio.put<Map<String, dynamic>>(
          ApiEndpoints.notificationPreferences,
          data: prefs.toJson());
      return NotificationPreferencesModel.fromJson(
          _data(resp.data!) as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
