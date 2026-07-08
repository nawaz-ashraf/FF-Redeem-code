// lib/data/models/app_settings_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RedeemPackageModel {
  final String name;
  final int coins;
  final String value;
  final String emoji;
  final String gradientColors; // e.g., "blue", "purple", "gold"
  final bool popular;

  const RedeemPackageModel({
    required this.name,
    required this.coins,
    required this.value,
    required this.emoji,
    required this.gradientColors,
    required this.popular,
  });

  factory RedeemPackageModel.fromMap(Map<String, dynamic> map) {
    return RedeemPackageModel(
      name: map['name'] ?? '',
      coins: (map['coins'] ?? 0).toInt(),
      value: map['value'] ?? '',
      emoji: map['emoji'] ?? '💎',
      gradientColors: map['gradientColors'] ?? 'blue',
      popular: map['popular'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'coins': coins,
      'value': value,
      'emoji': emoji,
      'gradientColors': gradientColors,
      'popular': popular,
    };
  }
}

class AppSettingsModel {
  final int dailyAdLimit;
  final int dailyScratchLimit;
  final int dailySpinLimit;
  final int rewardPerAd;
  final int rewardDailyLogin;
  final int minimumRedeem;
  final bool maintenanceMode;
  final List<RedeemPackageModel> redeemPackages;

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
    required this.redeemPackages,
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
      redeemPackages: [
        RedeemPackageModel(
          name: '₹100 Reward Code',
          coins: 2500,
          value: '₹100',
          emoji: '💎',
          gradientColors: 'blue',
          popular: false,
        ),
        RedeemPackageModel(
          name: '₹200 Reward Code',
          coins: 5000,
          value: '₹200',
          emoji: '💎💎',
          gradientColors: 'purple',
          popular: true,
        ),
        RedeemPackageModel(
          name: '₹400 Reward Code',
          coins: 10000,
          value: '₹400',
          emoji: '💎💎💎',
          gradientColors: 'gold',
          popular: false,
        ),
      ],
      latestVersion: '1.0.0',
      forceUpdate: false,
    );
  }

  factory AppSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<RedeemPackageModel> parsedPackages = [];
    if (data['redeemPackages'] != null) {
      parsedPackages = (data['redeemPackages'] as List)
          .map((e) => RedeemPackageModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } else {
      parsedPackages = AppSettingsModel.defaults().redeemPackages;
    }

    return AppSettingsModel(
      dailyAdLimit: (data['dailyAdLimit'] ?? 30).toInt(),
      dailyScratchLimit: (data['dailyScratchLimit'] ?? 2).toInt(),
      dailySpinLimit: (data['dailySpinLimit'] ?? 2).toInt(),
      rewardPerAd: (data['rewardPerAd'] ?? 5).toInt(),
      rewardDailyLogin: (data['rewardDailyLogin'] ?? 5).toInt(),
      minimumRedeem: (data['minimumRedeem'] ?? 2500).toInt(),
      maintenanceMode: data['maintenanceMode'] ?? false,
      redeemPackages: parsedPackages,
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
      'redeemPackages': redeemPackages.map((e) => e.toMap()).toList(),
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
    List<RedeemPackageModel>? redeemPackages,
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
      redeemPackages: redeemPackages ?? this.redeemPackages,
      latestVersion: latestVersion ?? this.latestVersion,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      storeUrl: storeUrl ?? this.storeUrl,
    );
  }
}
