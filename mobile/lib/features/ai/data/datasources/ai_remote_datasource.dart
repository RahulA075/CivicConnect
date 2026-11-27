import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/ai_analysis_model.dart';
import '../models/duplicate_check_model.dart';

abstract class AiRemoteDataSource {
  Future<AiAnalysisModel> analyzeText({
    required String title,
    required String description,
    String? municipalityId,
    String? issueId,
    String? imageUrl,
  });

  Future<DuplicateCheckResultModel> checkDuplicate({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 500,
  });

  Future<List<String>> getSmartSuggestions({
    required String title,
    String? description,
    String? municipalityId,
  });

  Future<AiAnalysisModel?> getAnalysisForIssue(String issueId);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final Dio _dio;
  const AiRemoteDataSourceImpl(this._dio);

  @override
  Future<AiAnalysisModel> analyzeText({
    required String title,
    required String description,
    String? municipalityId,
    String? issueId,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      if (municipalityId != null) 'municipalityId': municipalityId,
      if (issueId != null) 'issueId': issueId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

    final response = await _dio.post(
      ApiEndpoints.aiAnalyzeText,
      data: body,
    );

    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return AiAnalysisModel.fromJson(data);
  }

  @override
  Future<DuplicateCheckResultModel> checkDuplicate({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String municipalityId,
    int radiusMetres = 500,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'municipalityId': municipalityId,
      'radiusMetres': radiusMetres,
    };

    final response = await _dio.post(
      ApiEndpoints.aiCheckDuplicate,
      data: body,
    );

    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return DuplicateCheckResultModel.fromJson(data);
  }

  @override
  Future<List<String>> getSmartSuggestions({
    required String title,
    String? description,
    String? municipalityId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      if (description != null) 'description': description,
      if (municipalityId != null) 'municipalityId': municipalityId,
    };

    final response = await _dio.post(ApiEndpoints.aiSuggest, data: body);
    final data = response.data['data'];
    if (data is List) return data.map((e) => e as String).toList();
    return [];
  }

  @override
  Future<AiAnalysisModel?> getAnalysisForIssue(String issueId) async {
    final response = await _dio.get(ApiEndpoints.aiIssueAnalysis(issueId));
    final data = response.data['data'];
    if (data == null) return null;
    return AiAnalysisModel.fromJson(data as Map<String, dynamic>);
  }
}
