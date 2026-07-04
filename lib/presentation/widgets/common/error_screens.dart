// lib/presentation/widgets/common/error_screens.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

/// Base error/empty state widget
class _ErrorStateWidget extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onRetry;

  const _ErrorStateWidget({
    required this.emoji,
    required this.title,
    required this.message,
    this.buttonText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(buttonText ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No Internet connection screen
class NoInternetScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoInternetScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _ErrorStateWidget(
        emoji: '📡',
        title: 'No Internet Connection',
        message:
            'Please check your internet connection and try again.',
        buttonText: 'Try Again',
        onRetry: onRetry,
      ),
    );
  }
}

/// Server error screen
class ServerErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const ServerErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _ErrorStateWidget(
        emoji: '🔥',
        title: 'Server Error',
        message:
            'Something went wrong on our end. Please try again later.',
        buttonText: 'Retry',
        onRetry: onRetry,
      ),
    );
  }
}

/// Firebase error screen
class FirebaseErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  const FirebaseErrorScreen({super.key, this.errorMessage, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _ErrorStateWidget(
        emoji: '⚠️',
        title: 'Connection Error',
        message: errorMessage ?? 'Unable to connect to the server. Please try again.',
        buttonText: 'Retry',
        onRetry: onRetry,
      ),
    );
  }
}

/// Ad failed to load screen
class AdFailedScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const AdFailedScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _ErrorStateWidget(
      emoji: '📺',
      title: 'Ad Not Available',
      message:
          'The ad could not be loaded. Please check your internet connection and try again.',
      buttonText: 'Retry Loading',
      onRetry: onRetry,
    );
  }
}

/// Maintenance mode screen
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const _ErrorStateWidget(
        emoji: '🔧',
        title: 'Under Maintenance',
        message:
            'We\'re performing scheduled maintenance. The app will be back shortly. Thank you for your patience!',
      ),
    );
  }
}

/// No rewards available screen
class NoRewardsScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoRewardsScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _ErrorStateWidget(
      emoji: '🎁',
      title: 'No Rewards Available',
      message:
          'You\'ve used all your rewards for today. Come back tomorrow for more!',
      buttonText: 'Refresh',
      onRetry: onRetry,
    );
  }
}

/// Empty transaction screen
class EmptyTransactionScreen extends StatelessWidget {
  const EmptyTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ErrorStateWidget(
      emoji: '📭',
      title: 'No Transactions Yet',
      message:
          'Your transaction history will appear here once you start earning and redeeming coins.',
    );
  }
}

/// 404 Not found screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _ErrorStateWidget(
        emoji: '🔍',
        title: 'Page Not Found',
        message: 'The page you\'re looking for doesn\'t exist.',
        buttonText: 'Go Home',
        onRetry: () => Navigator.of(context).pop(),
      ),
    );
  }
}
