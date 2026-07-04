// lib/core/constants/app_constants.dart
import 'dart:io';

class AppConstants {
  AppConstants._();

  static const String appName = 'FF Redeem Code';
  static const String appVersion = '1.0.0';

  // Coin rewards
  static const int adRewardCoins = 5;
  static const int dailyLoginCoins = 5;
  static const int referralCoins = 20;
  static const int maxDailyAds = 30;
  static const int maxDailyScratch = 2;
  static const int maxDailySpin = 2;

  // Redeem packages
  static const Map<String, int> redeemPackages = {
    '₹100 Code': 2500,
    '₹200 Code': 5000,
    '₹400 Code': 10000,
  };

  // Firestore collections
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String withdrawalsCollection = 'withdrawals';
  static const String redeemCodesCollection = 'redeemCodes';
  static const String referralsCollection = 'referrals';
  static const String dailyRewardsCollection = 'dailyRewards';
  static const String adRewardsCollection = 'adRewards';
  static const String spinHistoryCollection = 'spinHistory';
  static const String scratchHistoryCollection = 'scratchHistory';
  static const String notificationsCollection = 'notifications';
  static const String settingsCollection = 'settings';
  static const String bannedUsersCollection = 'bannedUsers';
  static const String adminLogsCollection = 'adminLogs';
  static const String appStatisticsCollection = 'appStatistics';

  // Hive boxes
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String transactionBox = 'transaction_box';

  // Secure storage keys
  static const String authTokenKey = 'auth_token';
  static const String deviceIdKey = 'device_id';
  static const String userIdKey = 'user_id';

  // Shared preferences keys
  static const String isOnboardingDoneKey = 'is_onboarding_done';
  static const String lastLoginDateKey = 'last_login_date';
  static const String dailyAdCountKey = 'daily_ad_count';
  static const String dailyScratchCountKey = 'daily_scratch_count';
  static const String dailySpinCountKey = 'daily_spin_count';
  static const String dailyStreakKey = 'daily_streak';
  static const String lastAdRewardDateKey = 'last_ad_reward_date';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String darkModeKey = 'dark_mode';

  // AdMob IDs (test IDs — replace with real ones before release)
  static String get admobRewardedAdId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return '';
  }

  static String get admobBannerAdId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  static String get admobInterstitialAdId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  // Notification channels
  static const String notificationChannelId = 'ff_redeem_channel';
  static const String notificationChannelName = 'FF Redeem Notifications';
  static const String notificationChannelDescription =
      'Notifications for rewards, redeem status, and announcements';

  // Scratch rewards
  static const List<int> scratchRewards = [2, 3, 4, 5, 6, 7, 8, 9, 10];

  // Spin rewards
  static const List<int> spinRewards = [2, 3, 4, 5, 6, 7, 8, 9, 10];

  // Streak bonuses (day -> coins)
  static const Map<int, int> streakBonuses = {
    1: 5,
    2: 8,
    3: 12,
    4: 15,
    5: 20,
    6: 25,
    7: 50,
  };

  // XP levels
  static const List<Map<String, dynamic>> levels = [
    {'level': 1, 'name': 'Rookie', 'minXP': 0, 'maxXP': 100},
    {'level': 2, 'name': 'Warrior', 'minXP': 100, 'maxXP': 300},
    {'level': 3, 'name': 'Elite', 'minXP': 300, 'maxXP': 600},
    {'level': 4, 'name': 'Diamond', 'minXP': 600, 'maxXP': 1000},
    {'level': 5, 'name': 'Heroic', 'minXP': 1000, 'maxXP': 1500},
    {'level': 6, 'name': 'Grandmaster', 'minXP': 1500, 'maxXP': 2500},
    {'level': 7, 'name': 'Legend', 'minXP': 2500, 'maxXP': 999999},
  ];

  // Interstitial ad rules
  static const int interstitialScreenInterval = 5;

  // Support
  static const String supportEmail = 'support@ffredeemcode.app';
  static const String privacyPolicyUrl = 'https://ffredeemcode.app/privacy';
  static const String termsUrl = 'https://ffredeemcode.app/terms';
}
