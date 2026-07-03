// lib/core/errors/app_exception.dart

abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}

class FirestoreException extends AppException {
  const FirestoreException({required super.message, super.code});
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.code});
}

class AdException extends AppException {
  const AdException({required super.message, super.code});
}

class RewardException extends AppException {
  const RewardException({required super.message, super.code});
}

class LimitExceededException extends AppException {
  const LimitExceededException({required super.message, super.code});
}

class BannedException extends AppException {
  const BannedException({required super.message, super.code});
}

class DuplicateAccountException extends AppException {
  const DuplicateAccountException({required super.message, super.code});
}

String getReadableErrorMessage(Object error) {
  if (error is AppException) return error.message;
  final errorStr = error.toString();
  if (errorStr.contains('network-request-failed') ||
      errorStr.contains('SocketException')) {
    return 'No internet connection. Please try again.';
  }
  if (errorStr.contains('user-not-found')) {
    return 'No account found with this email.';
  }
  if (errorStr.contains('wrong-password') ||
      errorStr.contains('invalid-credential')) {
    return 'Incorrect password. Please try again.';
  }
  if (errorStr.contains('email-already-in-use')) {
    return 'This email is already registered.';
  }
  if (errorStr.contains('too-many-requests')) {
    return 'Too many attempts. Please try again later.';
  }
  if (errorStr.contains('permission-denied')) {
    return 'Access denied. Please contact support.';
  }
  return 'Something went wrong. Please try again.';
}
