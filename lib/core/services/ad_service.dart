// lib/core/services/ad_service.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

class AdService {
  static RewardedAd? _rewardedAd;
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static bool _isLoadingRewarded = false;
  static bool _isLoadingInterstitial = false;
  static int _screenChangeCount = 0;

  /// Initialize AdMob SDK
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ── REWARDED ADS ─────────────────────────────────────────

  /// Load a rewarded ad
  static Future<void> loadRewardedAd({
    VoidCallback? onAdLoaded,
  }) async {
    if (_isLoadingRewarded || _rewardedAd != null) {
      onAdLoaded?.call();
      return;
    }

    _isLoadingRewarded = true;

    await RewardedAd.load(
      adUnitId: AppConstants.admobRewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  /// Show a rewarded ad — reward ONLY via onUserEarnedReward per spec
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
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onAdFailed?.call();
        // Try loading another
        loadRewardedAd();
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

  /// Check if a rewarded ad is ready
  static bool get isRewardedAdReady => _rewardedAd != null;

  // ── BANNER ADS (Home Screen Bottom Only) ──────────────────

  /// Create a banner ad for the home screen
  static BannerAd? createBannerAd({
    VoidCallback? onLoaded,
    VoidCallback? onFailed,
  }) {
    _bannerAd = BannerAd(
      adUnitId: AppConstants.admobBannerAdId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          debugPrint('BannerAd failed to load: $error');
          onFailed?.call();
        },
      ),
    );
    _bannerAd!.load();
    return _bannerAd;
  }

  /// Dispose the banner ad
  static void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ── INTERSTITIAL ADS ─────────────────────────────────────
  // Rules per spec:
  // - Every 5 screen changes
  // - Never after reward completion
  // - Never during redemption

  /// Load an interstitial ad
  static Future<void> loadInterstitialAd() async {
    if (_isLoadingInterstitial || _interstitialAd != null) return;

    _isLoadingInterstitial = true;

    await InterstitialAd.load(
      adUnitId: AppConstants.admobInterstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// Track screen changes and show interstitial every 5 changes
  /// Returns true if an interstitial was shown
  static bool onScreenChange({
    bool blockAfterReward = false,
    bool blockDuringRedeem = false,
  }) {
    if (blockAfterReward || blockDuringRedeem) return false;

    _screenChangeCount++;

    if (_screenChangeCount >= 5 && _interstitialAd != null) {
      _screenChangeCount = 0;
      _showInterstitial();
      return true;
    }

    return false;
  }

  static void _showInterstitial() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
      },
    );
    _interstitialAd?.show();
  }

  /// Reset screen change counter (call after reward)
  static void resetScreenCounter() {
    _screenChangeCount = 0;
  }

  // ── CLEANUP ──────────────────────────────────────────────

  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _bannerAd?.dispose();
    _bannerAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
