// lib/core/services/app_check_service.dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Firebase App Check initialization for preventing abuse
class AppCheckService {
  static Future<void> initialize() async {
    try {
      await FirebaseAppCheck.instance.activate(
        // Use debug provider in debug mode, Play Integrity in release
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttest,
      );
    } catch (e, stack) {
      debugPrint('AppCheckService initialization error (non-fatal): $e\n$stack');
    }
  }
}
