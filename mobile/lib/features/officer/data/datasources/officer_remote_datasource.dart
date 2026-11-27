import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../features/issues/data/models/issue_model.dart';
import '../models/analytics_model.dart';

abstract interface class OfficerRemoteDataSource {
  Future<List<IssueModel>> getDepartmentIssues({
    required String departmentId,
    String? status,
    int page,
    int size,
  });
  Future<List<IssueModel>> getMyTasks();
  Future<IssueModel> acceptIssue(String issueId);
  Future<void> rejectIssue(String issueId, String reason);
  Future<IssueModel> assignIssue(String issueId, String workerId, {String? note});
  Future<IssueModel> updateStatus(String issueId, String status, {String? note});
  Future<List<StatusHistoryModel>> getStatusHistory(String issueId);
  Future<List<WorkerModel>> getDepartmentWorkers({
    required String departmentId,
    required String municipalityId,
  });
  Future<DashboardSummaryModel> getDashboardSummary(String municipalityId);
  Future<List<TrendPointModel>> getIssueTrend({
    required String municipalityId,
    int days,
    String? departmentId,
  });
}

class OfficerRemoteDataSourceImpl implements OfficerRemoteDataSource {
  const OfficerRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  dynamic _data(Map<String, dynamic> envelope) =>
      envelope.containsKey('data') ? envelope['data'] : envelope;

  List<IssueModel> _parsePagedIssues(dynamic data) {
    final map  = data as Map<String, dynamic>;
    final list = (map['content'] as List<dynamic>?) ?? [];
    return list
        .map((e) => IssueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<IssueModel>> getDepartmentIssues({
    required String departmentId,
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.departmentIssues(departmentId),
        queryParameters: {
          'page': page, 'size': size,
          if (status != null) 'status': status,
        },
      );
      return _parsePagedIssues(_data(resp.data!));
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<List<IssueModel>> getMyTasks() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.myTasks);
      final list = _data(resp.data!) as List<dynamic>;
      return list.map((e) => IssueModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<IssueModel> acceptIssue(String issueId) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.acceptIssue(issueId));
      return IssueModel.fromJson(_data(resp.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<void> rejectIssue(String issueId, String reason) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.rejectIssue(issueId),
        data: {'reason': reason},
      );
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<IssueModel> assignIssue(String issueId, String workerId,
      {String? note}) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.assignIssue(issueId),
        data: {'assignedToId': workerId, if (note != null) 'note': note},
      );
      return IssueModel.fromJson(_data(resp.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<IssueModel> updateStatus(String issueId, String status,
      {String? note}) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.issueStatus(issueId),
        data: {'status': status, if (note != null) 'note': note},
      );
      return IssueModel.fromJson(_data(resp.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<List<StatusHistoryModel>> getStatusHistory(String issueId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.issueHistory(issueId));
      final list = _data(resp.data!) as List<dynamic>;
      return list
          .map((e) => StatusHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<List<WorkerModel>> getDepartmentWorkers({
    required String departmentId,
    required String municipalityId,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.departmentWorkers(departmentId),
        queryParameters: {'municipalityId': municipalityId},
      );
      final list = _data(resp.data!) as List<dynamic>;
      return list
          .map((e) => WorkerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<DashboardSummaryModel> getDashboardSummary(String municipalityId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.summary(municipalityId));
      return DashboardSummaryModel.fromJson(
          _data(resp.data!) as Map<String, dynamic>);
    } catch (e) { throw ErrorHandler.handle(e); }
  }

  @override
  Future<List<TrendPointModel>> getIssueTrend({
    required String municipalityId,
    int days = 30,
    String? departmentId,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trend(municipalityId),
        queryParameters: {
          'days': days,
          if (departmentId != null) 'departmentId': departmentId,
        },
      );
      final map  = _data(resp.data!) as Map<String, dynamic>;
      final list = map['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => TrendPointModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) { throw ErrorHandler.handle(e); }
  }
}
