// lib/presentation/pages/games/watch_ads_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/animations/animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reward_provider.dart';
import '../../widgets/common/error_screens.dart';

class WatchAdsPage extends ConsumerStatefulWidget {
  const WatchAdsPage({super.key});

  @override
  ConsumerState<WatchAdsPage> createState() => _WatchAdsPageState();
}

class _WatchAdsPageState extends ConsumerState<WatchAdsPage> {
  bool _isAdLoading = false;
  bool _isAdReady = false;
  bool _adFailed = false;
  int? _lastReward;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    setState(() {
      _isAdLoading = true;
      _adFailed = false;
    });

    AdService.loadRewardedAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isAdLoading = false;
            _isAdReady = true;
          });
        }
      },
    );

    // Timeout after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isAdLoading) {
        setState(() {
          _isAdLoading = false;
          _adFailed = true;
        });
      }
    });
  }

  Future<void> _watchAd() async {
    final userId = ref.read(currentUserProvider).value?.uid;
    if (userId == null) return;

    setState(() => _isAdLoading = true);

    await AdService.showRewardedAd(
      onUserEarnedReward: (reward, rewardId) async {
        // Only reward here — never before, never after close, never duplicate
        final coins = await ref
            .read(rewardNotifierProvider.notifier)
            .claimAdReward(rewardId);

        if (coins != null && mounted) {
          setState(() => _lastReward = coins);
          // Reset interstitial counter after reward
          AdService.resetScreenCounter();
          _showRewardDialog(coins);
        }
      },
      onAdDismissed: () {
        if (mounted) {
          setState(() {
            _isAdLoading = false;
            _isAdReady = false;
          });
          _loadAd(); // Preload next
        }
      },
      onAdFailed: () {
        if (mounted) {
          setState(() {
            _isAdLoading = false;
            _adFailed = true;
          });
        }
      },
    );
  }

  void _showRewardDialog(int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RewardPopup(
        coins: coins,
        title: 'Ad Reward! 📺',
        subtitle: 'Keep watching ads to earn more coins!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final limitsAsync = ref.watch(dailyLimitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Watch Ads'),
        backgroundColor: AppColors.surface,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Reward info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.blueGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent2.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('📺', style: TextStyle(fontSize: 48)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Watch & Earn',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${AppConstants.adRewardCoins} coins per ad',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .slideY(begin: 0.3, duration: 500.ms)
                    .fade(duration: 500.ms),

                const SizedBox(height: 24),

                // Remaining ads counter
                limitsAsync.when(
                  data: (limits) {
                    final remaining = limits['adsRemaining'] ?? 30;
                    final watched = AppConstants.maxDailyAds - remaining;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Today\'s Progress',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '$watched / ${AppConstants.maxDailyAds}',
                                style: TextStyle(
                                  color: remaining > 0
                                      ? AppColors.primary
                                      : AppColors.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: watched / AppConstants.maxDailyAds,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                remaining > 0
                                    ? AppColors.accent2
                                    : AppColors.success,
                              ),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            remaining > 0
                                ? '$remaining ads remaining today'
                                : 'You\'ve watched all ads for today! 🎉',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),

                const Spacer(),

                // Watch button or error state
                if (_adFailed)
                  AdFailedScreen(onRetry: _loadAd)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isAdReady && !_isAdLoading ? _watchAd : null,
                      icon: _isAdLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 28),
                      label: Text(
                        _isAdLoading
                            ? 'Loading Ad...'
                            : _isAdReady
                                ? 'Watch Ad (+${AppConstants.adRewardCoins} coins)'
                                : 'Loading...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                Text(
                  '⚠️ Watch complete ads to earn rewards. Do not close the ad early.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
