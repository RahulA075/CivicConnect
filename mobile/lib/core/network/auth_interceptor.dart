import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

/// Injects the JWT access token into every outgoing request.
/// On 401, attempts a single silent token refresh; if that also fails,
/// clears stored tokens so the app navigates to the login screen.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Dio dio, required Logger logger})
      : _dio = dio,
        _log = logger;

  final Dio _dio;
  final Logger _log;

  /// Track whether a refresh is in-flight to prevent re-entrancy.
  bool _isRefreshing = false;
  final List<RequestOptions> _pending = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Skip refresh if the failing request itself was the refresh call.
    if (err.requestOptions.path.contains(ApiEndpoints.refresh)) {
      await _clearAndReject(err, handler);
      return;
    }

    if (_isRefreshing) {
      _pending.add(err.requestOptions);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        await _clearAndReject(err, handler);
        return;
      }

      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = resp.data!;
      final newAccess  = data['accessToken']  as String;
      final newRefresh = data['refreshToken'] as String;

      await SecureStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      // Retry original request and any queued ones.
      _pending
        ..add(err.requestOptions)
        ..forEach(_retry);
      _pending.clear();

      handler.resolve(await _retry(err.requestOptions));
    } catch (_) {
      await _clearAndReject(err, handler);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions opts) {
    return _dio.request<dynamic>(
      opts.path,
      data: opts.data,
      queryParameters: opts.queryParameters,
      options: Options(
        method: opts.method,
        headers: opts.headers,
      ),
    );
  }

  Future<void> _clearAndReject(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _log.w('Token refresh failed — clearing auth state');
    await SecureStorage.clearTokens();
    handler.next(err);
  }
}
