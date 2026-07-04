// lib/core/errors/app_exception.dart

/// Base exception class for the app
abstract class AppException implements Exception {
  final String message;
  const AppException({required this.message});

  @override
  String toString() => message;
}

/// Authentication related errors
class AuthException extends AppException {
  const AuthException({required super.message});
}

/// Duplicate account (device or UID)
class DuplicateAccountException extends AppException {
  const DuplicateAccountException({required super.message});
}

/// User is banned
class BannedException extends AppException {
  const BannedException({required super.message});
}

/// Validation errors (input, limits)
class ValidationException extends AppException {
  const ValidationException({required super.message});
}

/// Daily limit exceeded
class LimitExceededException extends AppException {
  const LimitExceededException({required super.message});
}

/// Firestore operation error
class FirestoreException extends AppException {
  const FirestoreException({required super.message});
}

/// Network/connectivity error
class NetworkException extends AppException {
  const NetworkException({required super.message});
}

/// Ad loading/display error
class AdException extends AppException {
  const AdException({required super.message});
}

/// Storage/file operation error
class StorageException extends AppException {
  const StorageException({required super.message});
}
