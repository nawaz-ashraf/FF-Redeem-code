import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FaqHelpPage extends StatelessWidget {
  const FaqHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ & Help', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            _buildFaqItem(
              'How can I earn more coins?',
              'You can earn more coins by completing daily tasks, spinning the wheel, scratching cards, watching video ads, and inviting your friends using your referral link.',
            ),
            _buildFaqItem(
              'Why did my coins disappear?',
              'Coins do not expire. If your balance seems incorrect, please check your transaction history to ensure a redemption wasn\'t processed. If you still suspect an error, contact our support team.',
            ),
            _buildFaqItem(
              'How long does a redemption take?',
              'Most redemptions are processed within 24-48 hours. During peak times, it may take up to 72 hours for our team to manually verify and send the reward code to your account.',
            ),
            _buildFaqItem(
              'Are the rewards real?',
              'Yes, absolutely! We purchase official Google Play and in-game redeem codes from authorized distributors and distribute them to our users once they accumulate enough coins.',
            ),
            _buildFaqItem(
              'My referral link isn\'t working',
              'Please make sure your friend downloads the app using your exact link and registers a new account. If they already had the app installed or used another link, you will not receive the bonus.',
            ),
            _buildFaqItem(
              'What happens if I use VPN?',
              'Using a VPN, proxy, or any automated tools (like auto-clickers) violates our terms of service. It will result in immediate and permanent account suspension and forfeiture of your coins.',
            ),
            _buildFaqItem(
              'How to update my profile details?',
              'Currently, basic profile details are pulled directly from your linked Google account to maintain security. You cannot change this manually within the app.',
            ),
            _buildFaqItem(
              'Why is my account suspended?',
              'Accounts are typically suspended for violating our terms, such as using multiple accounts on one device, exploiting bugs, or using VPNs. Suspensions are final and cannot be appealed.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
