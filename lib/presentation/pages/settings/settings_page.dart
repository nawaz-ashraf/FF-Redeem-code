// lib/presentation/pages/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _appVersion = '';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version} (${info.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Appearance section
            _buildSectionHeader('Appearance'),
            _buildSettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Theme',
              subtitle: isDarkMode ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(isDarkModeProvider.notifier).state = value;
                },
                activeColor: AppColors.primary,
              ),
            ),

            // Notifications section
            _buildSectionHeader('Notifications'),
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                activeColor: AppColors.primary,
              ),
            ),

            // Legal section
            _buildSectionHeader('Legal'),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => _openUrl(AppConstants.termsUrl),
            ),

            // Support section
            _buildSectionHeader('Support'),
            _buildSettingsTile(
              icon: Icons.support_agent_outlined,
              title: 'Contact Us',
              subtitle: AppConstants.supportEmail,
              onTap: () => _openUrl('mailto:${AppConstants.supportEmail}'),
            ),
            _buildSettingsTile(
              icon: Icons.star_outline,
              title: 'Rate App',
              subtitle: 'Leave us a review on Play Store',
              onTap: () {
                // Open Play Store listing
              },
            ),
            _buildSettingsTile(
              icon: Icons.share_outlined,
              title: 'Share App',
              subtitle: 'Invite friends to earn more coins!',
              onTap: () {
                Share.share(
                  'Earn free coins with FF Redeem Code app! Download now and use my referral code.',
                );
              },
            ),

            // About section
            _buildSectionHeader('About'),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: _appVersion.isEmpty ? 'Loading...' : _appVersion,
            ),

            // Danger zone
            _buildSectionHeader('Account'),
            _buildSettingsTile(
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              iconColor: AppColors.error,
              titleColor: AppColors.error,
              onTap: () => _showDeleteAccountDialog(),
            ),

            const SizedBox(height: 32),
            Center(
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.arrow_forward_ios,
                    color: AppColors.textHint, size: 14)
                : null),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is permanent and cannot be undone. All your data, coins, and transaction history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final user = ref.read(currentUserProvider).value;
              if (user != null) {
                await ref
                    .read(authRepositoryProvider)
                    .deleteAccount(user.uid);
                await ref
                    .read(authNotifierProvider.notifier)
                    .signOut();
                if (mounted) context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
