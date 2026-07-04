// lib/data/repositories/settings_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../models/app_settings_model.dart';

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

  /// Check if force update is required
  Future<Map<String, dynamic>> checkAppVersion(String currentVersion) async {
    final settings = await getAppSettings();
    final isUpdateAvailable = currentVersion != settings.latestVersion;
    return {
      'isUpdateAvailable': isUpdateAvailable,
      'forceUpdate': settings.forceUpdate && isUpdateAvailable,
      'latestVersion': settings.latestVersion,
    };
  }
}
