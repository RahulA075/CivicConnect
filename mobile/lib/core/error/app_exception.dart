/// Base class for all application-level exceptions.
/// Thrown at the data layer; caught and converted to [Failure] at the domain boundary.
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// HTTP / network error from Dio.
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode});
}

/// 401 — access token expired or invalid.
final class UnauthorisedException extends AppException {
  const UnauthorisedException([String message = 'Unauthorised'])
      : super(message, statusCode: 401);
}

/// 403 — authenticated but not allowed.
final class ForbiddenException extends AppException {
  const ForbiddenException([String message = 'Forbidden'])
      : super(message, statusCode: 403);
}

/// 404 — resource not found.
final class NotFoundException extends AppException {
  const NotFoundException([String message = 'Resource not found'])
      : super(message, statusCode: 404);
}

/// 409 — conflict (e.g. duplicate issue, email already registered).
final class ConflictException extends AppException {
  const ConflictException([String message = 'Conflict'])
      : super(message, statusCode: 409);
}

/// 422 — validation / business-rule violation.
final class ValidationException extends AppException {
  const ValidationException(super.message, {super.statusCode = 422});
}

/// 5xx — server error.
final class ServerException extends AppException {
  const ServerException([String message = 'Server error'])
      : super(message, statusCode: 500);
}

/// Device has no internet access.
final class NoInternetException extends AppException {
  const NoInternetException() : super('No internet connection');
}

/// Request timed out.
final class TimeoutException extends AppException {
  const TimeoutException() : super('Request timed out');
}

/// Any error that does not fit the above categories.
final class UnknownException extends AppException {
  const UnknownException([String message = 'An unexpected error occurred'])
      : super(message);
}
