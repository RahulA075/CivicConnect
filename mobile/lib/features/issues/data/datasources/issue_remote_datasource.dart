import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/error_handler.dart';
import '../models/issue_model.dart';
import '../models/nearby_issue_model.dart';

abstract interface class IssueRemoteDataSource {
  Future<List<IssueModel>> getPublicFeed({
    required String municipalityId,
    int page,
    int size,
    String? categoryId,
    String? status,
  });
  Future<List<IssueModel>> getMyIssues({int page, int size});
  Future<List<NearbyIssueModel>> getNearbyIssues({
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres,
  });
  Future<List<NearbyIssueModel>> getMapIssues({
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres,
    String? status,
    String? categoryId,
  });
  Future<IssueModel> getIssueById(String id);
  Future<IssueModel> reportIssue({
    required String title,
    required String description,
    required String categoryId,
    required double latitude,
    required double longitude,
    required String address,
    String? priority,
    bool anonymous,
    List<File> images,
  });
  Future<IssueModel> upvoteIssue(String id);
  Future<IssueModel> trackIssue(String trackingId);
  Future<List<Map<String, dynamic>>> getCategories(String municipalityId);
}

class IssueRemoteDataSourceImpl implements IssueRemoteDataSource {
  const IssueRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  /// Unwrap ApiResponse envelope.
  dynamic _unwrap(Map<String, dynamic> envelope) =>
      envelope.containsKey('data') ? envelope['data'] : envelope;

  List<IssueModel> _parsePagedList(dynamic data) {
    final map = data as Map<String, dynamic>;
    final list = (map['content'] as List<dynamic>?) ?? [];
    return list
        .map((e) => IssueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<IssueModel>> getPublicFeed({
    required String municipalityId,
    int page = 0,
    int size = 20,
    String? categoryId,
    String? status,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.publicFeed,
        queryParameters: {
          'municipalityId': municipalityId,
          'page': page,
          'size': size,
          if (categoryId != null) 'categoryId': categoryId,
          if (status     != null) 'status':     status,
        },
      );
      return _parsePagedList(_unwrap(resp.data!));
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<IssueModel>> getMyIssues({int page = 0, int size = 20}) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.myIssues,
        queryParameters: {'page': page, 'size': size},
      );
      return _parsePagedList(_unwrap(resp.data!));
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<NearbyIssueModel>> getNearbyIssues({
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 200,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.nearbyIssues,
        queryParameters: {
          'lat':            latitude,
          'lng':            longitude,
          'radius':         radiusMetres,
          'municipalityId': municipalityId,
        },
      );
      final data = _unwrap(resp.data!) as List<dynamic>;
      return data
          .map((e) => NearbyIssueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<NearbyIssueModel>> getMapIssues({
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 5000,
    String? status,
    String? categoryId,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.mapIssues,
        queryParameters: {
          'lat':            latitude,
          'lng':            longitude,
          'radius':         radiusMetres,
          'municipalityId': municipalityId,
          if (status     != null) 'status':     status,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );
      final data = _unwrap(resp.data!) as List<dynamic>;
      return data
          .map((e) => NearbyIssueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<IssueModel> getIssueById(String id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.issueById(id));
      return IssueModel.fromJson(_unwrap(resp.data!) as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<IssueModel> reportIssue({
    required String title,
    required String description,
    required String categoryId,
    required double latitude,
    required double longitude,
    required String address,
    String?  priority,
    bool     anonymous = false,
    List<File> images  = const [],
  }) async {
    try {
      // Backend accepts JSON (no multipart for now — images via separate upload)
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.issues,
        data: {
          'title':       title,
          'description': description,
          'categoryId':  categoryId,
          'latitude':    latitude,
          'longitude':   longitude,
          'addressText': address,
          if (priority != null) 'priority': priority,
          'anonymous': anonymous,
        },
      );
      return IssueModel.fromJson(_unwrap(resp.data!) as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<IssueModel> upvoteIssue(String id) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.issueUpvote(id));
      return IssueModel.fromJson(_unwrap(resp.data!) as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<IssueModel> trackIssue(String trackingId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.trackIssue(trackingId));
      return IssueModel.fromJson(_unwrap(resp.data!) as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories(String municipalityId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.categories,
        queryParameters: {'municipalityId': municipalityId},
      );
      final data = _unwrap(resp.data!) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
