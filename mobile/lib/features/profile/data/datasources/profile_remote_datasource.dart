import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/error_handler.dart';
import '../models/profile_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> updateProfile({String? fullName, String? phone, String? bio});
  Future<String> uploadAvatar(File image);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      return ProfileModel.fromJson(resp.data!);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    String? fullName,
    String? phone,
    String? bio,
  }) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.me,
        data: {
          if (fullName != null) 'fullName': fullName,
          if (phone    != null) 'phone':    phone,
          if (bio      != null) 'bio':      bio,
        },
      );
      return ProfileModel.fromJson(resp.data!);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<String> uploadAvatar(File image) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(image.path),
      });
      final resp = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.me}/avatar',
        data: formData,
      );
      return resp.data!['avatarUrl'] as String;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
