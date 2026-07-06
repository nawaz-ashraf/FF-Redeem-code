// lib/core/utils/auth_error_mapper.dart

/// Maps Firebase Auth error codes to user-friendly messages.
String mapFirebaseAuthError(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
      return 'Incorrect email or password. Please try again.';
    case 'user-not-found':
      return 'No account found with this email.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
