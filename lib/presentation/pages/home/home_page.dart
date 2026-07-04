// lib/presentation/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reward_provider.dart';
import '../../widgets/common/coin_balance_widget.dart';
import '../../widgets/home/reward_card.dart';
import '../../widgets/home/streak_widget.dart';
import '../../widgets/home/notice_banner.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/services/ad_service.dart';
import '../../widgets/home/daily_login_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late AnimationController _coinPulseController;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _coinPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyLogin();
    });

    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(
      onLoaded: () {
        if (mounted) {
          setState(() {
            _isBannerLoaded = true;
          });
        }
      },
      onFailed: () {
        if (mounted) {
          setState(() {
            _isBannerLoaded = false;
          });
        }
      },
    );
  }

  Future<void> _checkDailyLogin() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final limits = await ref.read(rewardRepositoryProvider).getDailyLimits(user.uid);
    if (limits['loginClaimed'] == 0) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => DailyLoginDialog(userId: user.uid),
        );
      }
    }
  }

  @override
  void dispose() {
    _coinPulseController.dispose();
    AdService.disposeBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: userAsync.when(
        loading: () => _buildLoadingState(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox();
          return _buildHomeContent(user);
        },
      ),
      bottomNavigationBar: _isBannerLoaded && _bannerAd != null
          ? Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(UserModel user) {
    // XP system removed

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: const SizedBox(),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user.name.split(' ').first}! 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'ID: ${user.uuid.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CoinBalanceWidget(coins: user.coins),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notice banner
                    const NoticeBanner(),
                    const SizedBox(height: 16),

                    // Coin balance card
                    _buildStatsCard(user)
                        .animate()
                        .slideY(begin: 0.3, duration: 500.ms)
                        .fade(duration: 500.ms),

                    const SizedBox(height: 20),

                    // Streak widget
                    StreakWidget(streak: user.dailyStreak)
                        .animate(delay: 100.ms)
                        .slideY(begin: 0.3, duration: 500.ms)
                        .fade(duration: 500.ms),

                    const SizedBox(height: 20),

                    // Earn section header
                    Text(
                      'Earn Coins',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete tasks to earn coins for rewards',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // Reward cards grid
                    _buildRewardCardsGrid(),

                    const SizedBox(height: 20),

                    // Today's progress
                    _buildTodayProgress(),

                    const SizedBox(height: 20),
                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rewards are subject to availability. We never promise unlimited diamonds.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A42), Color(0xFF0F1A32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: _coinPulseController,
                      builder: (context, child) => Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            user.coins.toString(),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.gold,
                              letterSpacing: -1,
                              shadows: [
                                Shadow(
                                  color: AppColors.gold.withOpacity(
                                    0.3 + _coinPulseController.value * 0.2,
                                  ),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 6),
                            child: Text(
                              'coins',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🪙', style: TextStyle(fontSize: 32)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatChip('📊', user.totalEarnedCoins.toString(), 'Total Earned'),
              const SizedBox(width: 8),
              _buildStatChip('✅', user.totalRedeemedCoins.toString(), 'Redeemed'),
              const SizedBox(width: 8),
              _buildStatChip('👥', '${user.referralCount}', 'Referrals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCardsGrid() {
    final cards = [
      RewardCardData(
        title: 'Daily Login',
        subtitle: '+5 to +50 coins',
        emoji: '🎁',
        gradient: AppColors.primaryGradient,
        badge: 'DAILY',
        onTap: () => _showDailyLogin(),
      ),
      RewardCardData(
        title: 'Watch Ads',
        subtitle: '+5 coins each',
        emoji: '📺',
        gradient: AppColors.blueGradient,
        badge: '30/day',
        onTap: () => context.push('/watch-ads'), // Will trigger ad
      ),
      RewardCardData(
        title: 'Scratch Card',
        subtitle: '2-10 coins',
        emoji: '🎴',
        gradient: AppColors.purpleGradient,
        badge: '2/day',
        onTap: () => context.push('/scratch'),
      ),
      RewardCardData(
        title: 'Spin Wheel',
        subtitle: '2-10 coins',
        emoji: '🎡',
        gradient: AppColors.greenGradient,
        badge: '2/day',
        onTap: () => context.push('/spin'),
      ),
      RewardCardData(
        title: 'Invite Friends',
        subtitle: '+20 coins each',
        emoji: '👥',
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFEE0979)],
        ),
        badge: 'REFERRAL',
        onTap: () => context.go('/profile'),
      ),
      RewardCardData(
        title: 'Redeem Coins',
        subtitle: 'Get reward codes',
        emoji: '💎',
        gradient: AppColors.goldGradient,
        badge: 'REDEEM',
        onTap: () => context.go('/redeem'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => RewardCard(data: cards[i])
          .animate(delay: (i * 80).ms)
          .slideY(begin: 0.3, duration: 400.ms)
          .fade(duration: 400.ms),
    );
  }

  Widget _buildTodayProgress() {
    return FutureBuilder<Map<String, int>>(
      future: ref.read(rewardRepositoryProvider).getDailyLimits(
            ref.read(currentUserProvider).value?.uid ?? '',
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final limits = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Progress",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              _buildProgressRow(
                '📺 Ads Watched',
                AppConstants.maxDailyAds - (limits['adsRemaining'] ?? 30),
                AppConstants.maxDailyAds,
                AppColors.accent2,
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                '🎴 Scratch Cards',
                AppConstants.maxDailyScratch - (limits['scratchRemaining'] ?? 2),
                AppConstants.maxDailyScratch,
                AppColors.accent1,
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                '🎡 Spin Wheel',
                AppConstants.maxDailySpin - (limits['spinRemaining'] ?? 2),
                AppConstants.maxDailySpin,
                AppColors.accent3,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressRow(
      String label, int done, int total, Color color) {
    final progress = total > 0 ? done / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '$done / $total',
              style: TextStyle(
                fontSize: 12,
                color: done >= total ? AppColors.success : AppColors.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  void _showDailyLogin() {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    showDialog(
      context: context,
      builder: (_) => DailyLoginDialog(userId: user.uid),
    );
  }
}
