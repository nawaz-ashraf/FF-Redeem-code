// lib/core/utils/app_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  static String formatCoins(int coins) {
    if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K';
    }
    return coins.toString();
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String generateReferralCode(String userId) {
    return 'FF${userId.substring(0, 6).toUpperCase()}';
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : isSuccess
                ? Colors.green.shade700
                : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String maskCode(String code) {
    if (code.length <= 4) return '****';
    return '${code.substring(0, 4)}${'*' * (code.length - 4)}';
  }

  static Map<String, dynamic> getLevelInfo(int xp) {
    const levels = [
      {'level': 1, 'name': 'Rookie', 'minXP': 0, 'maxXP': 100},
      {'level': 2, 'name': 'Warrior', 'minXP': 100, 'maxXP': 300},
      {'level': 3, 'name': 'Elite', 'minXP': 300, 'maxXP': 600},
      {'level': 4, 'name': 'Diamond', 'minXP': 600, 'maxXP': 1000},
      {'level': 5, 'name': 'Heroic', 'minXP': 1000, 'maxXP': 1500},
      {'level': 6, 'name': 'Grandmaster', 'minXP': 1500, 'maxXP': 2500},
      {'level': 7, 'name': 'Legend', 'minXP': 2500, 'maxXP': 999999},
    ];

    for (final level in levels.reversed) {
      if (xp >= (level['minXP'] as int)) {
        return level;
      }
    }
    return levels.first;
  }
}
