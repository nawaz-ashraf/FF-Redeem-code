// lib/presentation/widgets/home/daily_login_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/reward_provider.dart';

class DailyLoginDialog extends ConsumerStatefulWidget {
  final String userId;

  const DailyLoginDialog({super.key, required this.userId});

  @override
  ConsumerState<DailyLoginDialog> createState() => _DailyLoginDialogState();
}

class _DailyLoginDialogState extends ConsumerState<DailyLoginDialog> {
  bool _isClaiming = false;
  bool _claimed = false;
  int _earnedCoins = 0;
  int _streak = 0;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    setState(() => _isClaiming = true);

    final result = await ref
        .read(rewardNotifierProvider.notifier)
        .claimDailyLogin();

    if (mounted) {
      if (result != null) {
        setState(() {
          _claimed = true;
          _earnedCoins = result['coins'] as int;
          _streak = result['streak'] as int;
        });
        _confettiController.play();
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ref.read(rewardNotifierProvider).error ??
                    'Already claimed today'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: _claimed
                ? _buildClaimedContent()
                : _buildClaimContent(),
          ),
          if (_claimed)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    colors: const [
                      AppColors.primary,
                      AppColors.gold,
                      AppColors.accent1,
                      AppColors.accent2,
                    ],
                    numberOfParticles: 30,
                    maxBlastForce: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClaimContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Center(
            child: Text('🎁', style: TextStyle(fontSize: 40)),
          ),
        )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .fade(duration: 400.ms),
        const SizedBox(height: 20),
        Text(
          'Daily Login Bonus!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Come back every day for bigger rewards',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Streak days preview
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (i) {
            final day = i + 1;
            final bonus = AppConstants.streakBonuses[day] ?? 5;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: day == 7
                          ? AppColors.gold.withOpacity(0.2)
                          : AppColors.surfaceLight,
                      border: Border.all(
                        color: day == 7
                            ? AppColors.gold
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: day == 7
                              ? AppColors.gold
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+$bonus',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        // Claim button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isClaiming ? null : _claim,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isClaiming
                ? const CircularProgressIndicator(color: Colors.white)
                : Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Claim Daily Bonus 🎉',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Remind me later',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildClaimedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.goldGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Text('🪙', style: TextStyle(fontSize: 48)),
          ),
        )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .fade(duration: 400.ms),
        const SizedBox(height: 20),
        Text(
          '+$_earnedCoins Coins! 🎉',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.gold,
          ),
        ).animate().slideY(begin: 0.3, duration: 400.ms).fade(),
        const SizedBox(height: 8),
        Text(
          'Day $_streak streak complete!',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
