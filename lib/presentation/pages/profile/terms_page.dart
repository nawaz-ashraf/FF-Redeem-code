import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: Today',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('1. User Responsibilities'),
              _buildSectionText(
                  'By using this app, you agree to provide accurate information and refrain from using automated systems, emulators, or VPNs to manipulate the reward system.'),
              _buildSectionTitle('2. Reward Rules'),
              _buildSectionText(
                  'Rewards are earned by completing tasks, watching ads, or participating in games. The availability and value of tasks may change without prior notice.'),
              _buildSectionTitle('3. Coin Policy'),
              _buildSectionText(
                  'Coins earned in the app hold no real-world currency value until successfully redeemed for the offered reward codes. Coins cannot be transferred between accounts.'),
              _buildSectionTitle('4. Redemption Policy'),
              _buildSectionText(
                  'Redemption requests are processed manually or automatically. We reserve the right to delay or reject redemptions if fraudulent activity is suspected.'),
              _buildSectionTitle('5. Account Suspension Rules'),
              _buildSectionText(
                  'Any violation of these terms, including the use of multiple accounts, auto-clickers, or exploits, will result in immediate and permanent account suspension and forfeiture of all coins.'),
              _buildSectionTitle('6. Disclaimer'),
              _buildSectionText(
                  'The application is provided "as is" without warranty. We do not guarantee uninterrupted access or that the app will always be error-free.'),
              _buildSectionTitle('7. Google Play Compliance'),
              _buildSectionText(
                  'This application complies with Google Play policies. We are not affiliated with, endorsed, or sponsored by Google or any other trademark owners mentioned within the app.'),
              _buildSectionTitle('8. Copyright Notice'),
              _buildSectionText(
                  'All content, designs, and assets within this application are the property of Game Redeem Code. Unauthorized copying or distribution is strictly prohibited.'),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.6,
      ),
    );
  }
}
