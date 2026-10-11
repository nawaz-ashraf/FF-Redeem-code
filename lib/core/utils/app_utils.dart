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

  /// Format a date as UTC yyyy-MM-dd to ensure consistent calendar day policy
  /// across restarts, reinstallation, and timezone changes.
  static String getRewardDayKey([DateTime? date]) {
    final d = (date ?? DateTime.now()).toUtc();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Check if two dates fall on the same UTC reward calendar day.
  static bool isSameRewardDay(DateTime a, DateTime b) {
    return getRewardDayKey(a) == getRewardDayKey(b);
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


}
