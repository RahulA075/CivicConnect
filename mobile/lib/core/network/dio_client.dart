import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import 'auth_interceptor.dart';

/// Singleton Dio instance factory.
///
/// Call [DioClient.create] once during app boot (in providers.dart) and
/// inject the returned instance everywhere via Riverpod.
abstract final class DioClient {
  static Dio create({
    required AppConfig config,
    required Logger logger,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
      ),
    );

    // Auth: inject + refresh tokens.
    dio.interceptors.add(AuthInterceptor(dio: dio, logger: logger));

    // Logging (dev/staging only).
    if (config.enableLogging) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody:  true,
          responseBody: true,
          logPrint: (o) => logger.d(o.toString()),
        ),
      );
    }

    return dio;
  }
}
