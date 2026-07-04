// lib/core/validators/validators.dart

/// Form field validators following the spec's validation rules
class Validators {
  Validators._();

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password strength
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate confirm password
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate user display name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  /// Validate Free Fire UID (numeric, typically 9-12 digits)
  static String? freeFireUID(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Free Fire UID is required';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Free Fire UID must contain only numbers';
    }
    if (trimmed.length < 6 || trimmed.length > 15) {
      return 'Please enter a valid Free Fire UID';
    }
    return null;
  }

  /// Validate referral code format
  static String? referralCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Referral code is optional
    }
    if (value.trim().length < 4) {
      return 'Invalid referral code';
    }
    return null;
  }

  /// Validate coin amount
  static String? coinAmount(String? value, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = int.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid number';
    }
    if (min != null && amount < min) {
      return 'Minimum amount is $min';
    }
    if (max != null && amount > max) {
      return 'Maximum amount is $max';
    }
    return null;
  }

  /// Validate redeem code (admin input)
  static String? redeemCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Redeem code is required';
    }
    if (value.trim().length < 4) {
      return 'Redeem code is too short';
    }
    return null;
  }

  /// Generic required field validator
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
