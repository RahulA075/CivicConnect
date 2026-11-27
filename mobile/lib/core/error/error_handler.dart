import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'failure.dart';

/// Converts raw exceptions (Dio, Dart) into typed [AppException]s,
/// and [AppException]s into domain [Failure]s.
abstract final class ErrorHandler {
  /// Maps a caught [Object] to a typed [AppException].
  static AppException handle(Object error) {
    if (error is AppException) return error;

    if (error is DioException) {
      return _handleDio(error);
    }

    return UnknownException(error.toString());
  }

  static AppException _handleDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NoInternetException();

      case DioExceptionType.badResponse:
        return _fromHttpStatus(
          e.response?.statusCode,
          _extractMessage(e.response),
        );

      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled');

      default:
        return UnknownException(e.message ?? 'Unknown Dio error');
    }
  }

  static AppException _fromHttpStatus(int? code, String message) =>
      switch (code) {
        401 => UnauthorisedException(message),
        403 => ForbiddenException(message),
        404 => NotFoundException(message),
        409 => ConflictException(message),
        422 => ValidationException(message),
        int c when c >= 500 => ServerException(message),
        _ => NetworkException(message, statusCode: code),
      };

  static String _extractMessage(Response<dynamic>? response) {
    if (response == null) return 'Unknown error';
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ??
            data['error'] as String? ??
            'Error ${response.statusCode}';
      }
    } catch (_) {}
    return 'Error ${response.statusCode}';
  }

  /// Converts an [AppException] to the matching [Failure].
  static Failure toFailure(AppException e) => switch (e) {
        UnauthorisedException() => UnauthorisedFailure(e.message),
        ForbiddenException()    => ForbiddenFailure(e.message),
        NotFoundException()     => NotFoundFailure(e.message),
        ConflictException()     => ConflictFailure(e.message),
        ValidationException()   => ValidationFailure(e.message),
        ServerException()       => ServerFailure(e.message),
        NoInternetException()   => const NoInternetFailure(),
        TimeoutException()      => const TimeoutFailure(),
        NetworkException()      => NetworkFailure(e.message),
        UnknownException()      => UnknownFailure(e.message),
      };
}
