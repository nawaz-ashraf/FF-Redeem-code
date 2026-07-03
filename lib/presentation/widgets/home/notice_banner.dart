// lib/presentation/widgets/home/notice_banner.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection('settings')
          .doc('announcements')
          .collection('items')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Default welcome banner
          return _buildDefaultBanner();
        }

        final notices = snapshot.data!.docs;
        return Column(
          children: notices.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildBanner(
              data['message'] ?? '',
              data['type'] ?? 'info',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A4A), Color(0xFF0F1A35)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('📢', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Welcome! Watch ads, scratch cards & spin the wheel to earn coins.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String message, String type) {
    Color color;
    String emoji;
    switch (type) {
      case 'warning':
        color = AppColors.warning;
        emoji = '⚠️';
        break;
      case 'success':
        color = AppColors.success;
        emoji = '✅';
        break;
      case 'error':
        color = AppColors.error;
        emoji = '🚨';
        break;
      default:
        color = AppColors.accent2;
        emoji = '📢';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
