// lib/presentation/providers/app_update_provider.dart
//
// Splash reads this provider once per cold start to decide whether to
// show the update dialog before routing to home / onboarding / login.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_update_status.dart';
import 'settings_provider.dart';

/// Fetches update status from Firestore and compares against installed version.
///
/// Returns [AppUpdateStatus] on success, or **null on any failure** (fail open).
/// A 5s timeout prevents splash from hanging on slow/offline networks.
///
/// Null is treated as "no update" by [SplashPage] — the app always continues.
final appUpdateCheckProvider = FutureProvider<AppUpdateStatus?>((ref) async {
  try {
    final repo = ref.read(settingsRepositoryProvider);
    return await repo.checkAppVersion().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Offline, timeout, Firestore error → never block the user.
    return null;
  }
});
