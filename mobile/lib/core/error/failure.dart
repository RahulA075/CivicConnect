import 'package:equatable/equatable.dart';

/// Domain-layer error representation.
/// Use [dartz.Either<Failure, T>] as the return type of use cases.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

final class UnauthorisedFailure extends Failure {
  const UnauthorisedFailure([super.message = 'Please log in again']);
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'You do not have permission']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

final class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Conflict detected']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again later.']);
}

final class NoInternetFailure extends Failure {
  const NoInternetFailure([super.message = 'No internet connection']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache read/write failed']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
