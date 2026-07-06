// lib/data/models/app_settings_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsModel {
  final int dailyAdLimit;
  final int dailyScratchLimit;
  final int dailySpinLimit;
  final int rewardPerAd;
  final int rewardDailyLogin;
  final int minimumRedeem;
  final bool maintenanceMode;

  // --- App update fields (settings/appConfig) ---
  /// Remote minimum version. Users below this may see an update prompt.
  final String latestVersion;

  /// When true AND user is outdated, splash shows a blocking update dialog.
  final bool forceUpdate;

  /// Optional changelog text shown in the update dialog.
  final String releaseNotes;

  /// Play Store link. Empty string falls back to AppConstants.defaultPlayStoreUrl.
  final String storeUrl;

  const AppSettingsModel({
    required this.dailyAdLimit,
    required this.dailyScratchLimit,
    required this.dailySpinLimit,
    required this.rewardPerAd,
    required this.rewardDailyLogin,
    required this.minimumRedeem,
    required this.maintenanceMode,
    required this.latestVersion,
    required this.forceUpdate,
    this.releaseNotes = '',
    this.storeUrl = '',
  });

  /// Default settings used when Firestore document doesn't exist
  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      dailyAdLimit: 30,
      dailyScratchLimit: 3,
      dailySpinLimit: 3,
      rewardPerAd: 5,
      rewardDailyLogin: 5,
      minimumRedeem: 2500,
      maintenanceMode: false,
      latestVersion: '1.0.0',
      forceUpdate: false,
    );
  }

  factory AppSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppSettingsModel(
      dailyAdLimit: (data['dailyAdLimit'] ?? 30).toInt(),
      dailyScratchLimit: (data['dailyScratchLimit'] ?? 2).toInt(),
      dailySpinLimit: (data['dailySpinLimit'] ?? 2).toInt(),
      rewardPerAd: (data['rewardPerAd'] ?? 5).toInt(),
      rewardDailyLogin: (data['rewardDailyLogin'] ?? 5).toInt(),
      minimumRedeem: (data['minimumRedeem'] ?? 2500).toInt(),
      maintenanceMode: data['maintenanceMode'] ?? false,
      latestVersion: data['latestVersion'] ?? '1.0.0',
      forceUpdate: data['forceUpdate'] ?? false,
      releaseNotes: data['releaseNotes'] ?? '',
      storeUrl: data['storeUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dailyAdLimit': dailyAdLimit,
      'dailyScratchLimit': dailyScratchLimit,
      'dailySpinLimit': dailySpinLimit,
      'rewardPerAd': rewardPerAd,
      'rewardDailyLogin': rewardDailyLogin,
      'minimumRedeem': minimumRedeem,
      'maintenanceMode': maintenanceMode,
      'latestVersion': latestVersion,
      'forceUpdate': forceUpdate,
      'releaseNotes': releaseNotes,
      'storeUrl': storeUrl,
    };
  }

  AppSettingsModel copyWith({
    int? dailyAdLimit,
    int? dailyScratchLimit,
    int? dailySpinLimit,
    int? rewardPerAd,
    int? rewardDailyLogin,
    int? minimumRedeem,
    bool? maintenanceMode,
    String? latestVersion,
    bool? forceUpdate,
    String? releaseNotes,
    String? storeUrl,
  }) {
    return AppSettingsModel(
      dailyAdLimit: dailyAdLimit ?? this.dailyAdLimit,
      dailyScratchLimit: dailyScratchLimit ?? this.dailyScratchLimit,
      dailySpinLimit: dailySpinLimit ?? this.dailySpinLimit,
      rewardPerAd: rewardPerAd ?? this.rewardPerAd,
      rewardDailyLogin: rewardDailyLogin ?? this.rewardDailyLogin,
      minimumRedeem: minimumRedeem ?? this.minimumRedeem,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      latestVersion: latestVersion ?? this.latestVersion,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      storeUrl: storeUrl ?? this.storeUrl,
    );
  }
}
