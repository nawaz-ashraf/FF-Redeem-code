import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy',
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
              _buildSectionTitle('1. Information Collection'),
              _buildSectionText(
                  'We collect information to provide better services to our users. This includes basic account info like your name and email address, as well as usage data such as ads watched and rewards claimed.'),
              _buildSectionTitle('2. How We Use Your Information'),
              _buildSectionText(
                  'Your information is used solely for the operation of the Game Redeem Code app. We use it to track your coin balance, process redemption requests, and ensure the security of our platform.'),
              _buildSectionTitle('3. Data Security'),
              _buildSectionText(
                  'We implement industry-standard security measures, including Firebase Authentication, to protect your data from unauthorized access or alteration.'),
              _buildSectionTitle('4. Third-Party Services'),
              _buildSectionText(
                  'We use third-party services like Google AdMob for advertisements. These services may collect information used to identify you in accordance with their own privacy policies.'),
              _buildSectionTitle('5. Data Deletion'),
              _buildSectionText(
                  'You have the right to request the deletion of your account and associated data. Please contact support for assistance.'),
              _buildSectionTitle('6. Changes to This Policy'),
              _buildSectionText(
                  'We reserve the right to update this Privacy Policy at any time. We will notify you of any changes by posting the new Privacy Policy on this page.'),
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
