// lib/data/models/app_update_status.dart
//
// Result of comparing the installed app version against Firestore config.
// Built by SettingsRepository.checkAppVersion() and consumed by splash + dialog.

class AppUpdateStatus {
  /// True when installed version is older than Firestore latestVersion.
  final bool updateAvailable;

  /// True only when [updateAvailable] AND Firestore forceUpdate is true.
  /// Drives blocking vs skippable dialog on splash.
  final bool forceUpdate;

  /// Running version from PackageInfo (pubspec.yaml version field).
  final String currentVersion;

  /// Target version from Firestore settings/appConfig.
  final String latestVersion;

  /// Optional changelog shown in the update dialog.
  final String releaseNotes;

  /// Play Store URL opened when user taps Update.
  final String storeUrl;

  const AppUpdateStatus({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.storeUrl,
  });
}
