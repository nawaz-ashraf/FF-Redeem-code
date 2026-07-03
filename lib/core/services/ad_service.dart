// lib/core/services/ad_service.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

class AdService {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static Future<void> loadRewardedAd({
    required VoidCallback onAdLoaded,
  }) async {
    if (_isLoading || _rewardedAd != null) {
      onAdLoaded();
      return;
    }

    _isLoading = true;

    await RewardedAd.load(
      adUnitId: AppConstants.admobRewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          onAdLoaded();
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  static Future<bool> showRewardedAd({
    required void Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailed,
  }) async {
    if (_rewardedAd == null) {
      onAdFailed?.call();
      return false;
    }

    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdDismissed?.call();
        // Preload next ad
        loadRewardedAd(onAdLoaded: () {});
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onAdFailed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        onUserEarnedReward(reward);
      },
    );

    return rewarded;
  }

  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
