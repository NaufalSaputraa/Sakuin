sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  E? get errorOrNull => switch (this) {
        Success() => null,
        Failure(:final error) => error,
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) {
    return switch (this) {
      Success(:final value) => success(value),
      Failure(:final error) => failure(error),
    };
  }
}

final class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}

sealed class AppError {
  final String message;
  const AppError(this.message);

  factory AppError.database(String message) = DatabaseError;
  factory AppError.notFound(String message) = NotFoundError;
  factory AppError.validation(String message) = ValidationError;
  factory AppError.parse(String message) = ParseError;
}

final class DatabaseError extends AppError {
  const DatabaseError(super.message);
}

final class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

final class ValidationError extends AppError {
  const ValidationError(super.message);
}

final class ParseError extends AppError {
  const ParseError(super.message);
}

final class PermissionError extends AppError {
  const PermissionError(super.message);
}
