// lib/data/repositories/settings_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/version_utils.dart';
import '../models/app_settings_model.dart';
import '../models/app_update_status.dart';

class SettingsRepository {
  final _firestore = FirebaseService.firestore;

  /// Read app settings from Firestore
  Future<AppSettingsModel> getAppSettings() async {
    final doc = await _firestore
        .collection(AppConstants.settingsCollection)
        .doc('appConfig')
        .get();

    if (!doc.exists) {
      return AppSettingsModel.defaults();
    }

    return AppSettingsModel.fromFirestore(doc);
  }

  /// Stream app settings for real-time updates
  Stream<AppSettingsModel> watchAppSettings() {
    return _firestore
        .collection(AppConstants.settingsCollection)
        .doc('appConfig')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return AppSettingsModel.defaults();
      return AppSettingsModel.fromFirestore(doc);
    });
  }

  /// Update app settings (admin only)
  Future<void> updateSettings(Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.settingsCollection)
        .doc('appConfig')
        .set(data, SetOptions(merge: true));
  }

  /// Initialize default settings if they don't exist
  Future<void> initializeDefaultSettings() async {
    final doc = await _firestore
        .collection(AppConstants.settingsCollection)
        .doc('appConfig')
        .get();

    if (!doc.exists) {
      await _firestore
          .collection(AppConstants.settingsCollection)
          .doc('appConfig')
          .set(AppSettingsModel.defaults().toFirestore());
    }
  }

  /// Check if app is in maintenance mode
  Future<bool> isMaintenanceMode() async {
    final settings = await getAppSettings();
    return settings.maintenanceMode;
  }

  /// Compare running app version against Firestore config.
  ///
  /// Flow:
  /// 1. Read installed version via package_info_plus
  /// 2. Fetch settings/appConfig from Firestore
  /// 3. Compare with VersionUtils (not string equality)
  /// 4. Return [AppUpdateStatus] for splash/dialog to act on
  ///
  /// Errors are handled upstream by [appUpdateCheckProvider] (fail open).
  Future<AppUpdateStatus> checkAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final settings = await getAppSettings();

    final updateAvailable = VersionUtils.isUpdateAvailable(
      current: currentVersion,
      latest: settings.latestVersion,
    );

    // Prefer remote store URL; fall back to app-wide default.
    final storeUrl = settings.storeUrl.isNotEmpty
        ? settings.storeUrl
        : AppConstants.defaultPlayStoreUrl;

    return AppUpdateStatus(
      updateAvailable: updateAvailable,
      // forceUpdate only applies when user is actually outdated.
      forceUpdate: updateAvailable && settings.forceUpdate,
      currentVersion: currentVersion,
      latestVersion: settings.latestVersion,
      releaseNotes: settings.releaseNotes,
      storeUrl: storeUrl,
    );
  }
}
