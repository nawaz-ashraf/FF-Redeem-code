// lib/presentation/pages/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: userAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (user) => user == null
              ? const Center(child: Text('Not logged in'))
              : _buildProfile(context, ref, user),
        ),
      ),
    );
  }

  Widget _buildProfile(
      BuildContext context, WidgetRef ref, UserModel user) {

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Profile picture
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: user.profileImage != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.profileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(
                                color: AppColors.primary, width: 2),
                          ),
                          child: const Icon(Icons.edit,
                              size: 14, color: AppColors.primary),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${user.uuid.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                          '🪙', user.coins.toString(), 'Coins', context),
                      _buildDivider(),
                      _buildStat(
                          '🔥',
                          user.dailyStreak.toString(),
                          'Streak',
                          context),
                      _buildDivider(),
                      _buildStat(
                          '👥',
                          user.referralCount.toString(),
                          'Referrals',
                          context),
                    ],
                  ),
                ],
              ),
            ),

            // Referral section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent1.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('👥', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Referral Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${user.referralCount} invited',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.referralCode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: user.referralCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Referral code copied! ✅'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {
                            Share.share(
                              'Join FF Redeem Code and earn coins! Use my referral code: ${user.referralCode}\n\nDownload the app now!',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '💰 Earn 20 coins for each friend who registers!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: 200.ms)
                  .slideY(begin: 0.3, duration: 400.ms)
                  .fade(),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
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
                      'Account Stats',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('💰 Total Earned', '${user.totalEarnedCoins} coins'),
                    _buildStatRow(
                        '💎 Total Redeemed', '${user.totalRedeemedCoins} coins'),
                    _buildStatRow('📅 Member Since',
                        AppUtils.formatDate(user.createdAt)),
                    _buildStatRow('✉️ Email', user.email ?? 'N/A'),
                  ],
                ),
              ),
            ),

            // Menu items
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (user.isAdmin)
                      _buildMenuItem(
                        context,
                        icon: Icons.admin_panel_settings,
                        label: 'Admin Dashboard',
                        color: AppColors.error,
                        onTap: () => context.push('/admin'),
                      ),
                    _buildMenuItem(
                      context,
                      icon: Icons.history,
                      label: 'Transaction History',
                      onTap: () => context.go('/history'),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.support_agent_outlined,
                      label: 'Contact Support',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.star_outline,
                      label: 'Rate App',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.share_outlined,
                      label: 'Share App',
                      onTap: () {
                        Share.share(
                          'Earn free coins with FF Redeem Code app! Download now.',
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.help_outline,
                      label: 'FAQ & Help',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      label: 'Logout',
                      color: AppColors.error,
                      showDivider: false,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Logout?'),
                            content: const Text(
                                'Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .signOut();
                          if (context.mounted) context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '⚠️ Rewards are subject to availability.\nWe never promise unlimited diamonds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
      String emoji, String value, String label, BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 48,
      width: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: color ?? AppColors.textSecondary,
            size: 22,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textHint,
            size: 14,
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}
