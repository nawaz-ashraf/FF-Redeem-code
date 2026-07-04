// lib/presentation/pages/games/spin_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/reward_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/ad_service.dart';

class SpinPage extends ConsumerStatefulWidget {
  const SpinPage({super.key});

  @override
  ConsumerState<SpinPage> createState() => _SpinPageState();
}

class _SpinPageState extends ConsumerState<SpinPage>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late ConfettiController _confettiController;

  bool _isSpinning = false;
  int? _reward;
  double _currentAngle = 0;

  final List<int> _rewards = AppConstants.spinRewards;
  final List<Color> _sectorColors = [
    AppColors.primary,
    AppColors.accent1,
    AppColors.accent2,
    AppColors.accent3,
    const Color(0xFFEB5757),
    AppColors.gold,
    const Color(0xFF00B4D8),
    AppColors.primary,
    AppColors.accent1,
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    AdService.loadRewardedAd();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning) return;

    if (!AdService.isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad is still loading. Please wait...')),
      );
      AdService.loadRewardedAd();
      return;
    }
    
    bool adSuccess = false;
    await AdService.showRewardedAd(
      onUserEarnedReward: (_) {
        adSuccess = true;
      },
    );
    
    if (!adSuccess) return;

    setState(() {
      _isSpinning = true;
      _reward = null;
    });

    // Simulate a random winning position
    final random = Random();
    final extraSpins = 5 + random.nextInt(3); // 5-7 full rotations
    final targetAngle =
        _currentAngle + (2 * pi * extraSpins) + random.nextDouble() * 2 * pi;

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _spinAnimation = Tween<double>(
      begin: _currentAngle,
      end: targetAngle,
    ).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.decelerate),
    );

    _spinController.forward();

    await Future.delayed(const Duration(milliseconds: 3500));

    // Claim reward
    final reward = await ref
        .read(rewardNotifierProvider.notifier)
        .claimSpinReward();

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _currentAngle = targetAngle % (2 * pi);
        _isSpinning = false;
        _reward = reward;
      });
      AdService.loadRewardedAd();

      if (reward != null) {
        _confettiController.play();
      } else {
        final error = ref.read(rewardNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Could not claim spin reward'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // AppBar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '🎡 Spin Wheel',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  // Remaining spins
                  FutureBuilder<Map<String, int>>(
                    future: ref.read(rewardRepositoryProvider).getDailyLimits(
                          ref.read(currentUserProvider).value?.uid ?? '',
                        ),
                    builder: (context, snap) {
                      final remaining = snap.data?['spinRemaining'] ??
                          AppConstants.maxDailySpin;
                      return Text(
                        '$remaining spin${remaining != 1 ? 's' : ''} remaining today',
                        style: TextStyle(
                          color: remaining > 0
                              ? AppColors.success
                              : AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Spin wheel
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // Wheel
                      AnimatedBuilder(
                        animation: _isSpinning
                            ? _spinAnimation
                            : AlwaysStoppedAnimation(_currentAngle),
                        builder: (context, child) => Transform.rotate(
                          angle: _isSpinning
                              ? _spinAnimation.value
                              : _currentAngle,
                          child: CustomPaint(
                            size: const Size(300, 300),
                            painter: _WheelPainter(
                              rewards: _rewards,
                              colors: _sectorColors,
                            ),
                          ),
                        ),
                      ),
                      // Center circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🎯',
                              style: TextStyle(fontSize: 28)),
                        ),
                      ),
                      // Pointer
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 24,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_drop_down,
                              color: AppColors.primary, size: 28),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Result
                  if (_reward != null)
                    Text(
                      'You won $_reward coins! 🎉',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 24),

                  // Spin button
                  GestureDetector(
                    onTap: _isSpinning ? null : _spin,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 200,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: _isSpinning
                            ? const LinearGradient(
                                colors: [Color(0xFF455A64), Color(0xFF37474F)])
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: _isSpinning
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Center(
                        child: _isSpinning
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_arrow, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'UNLOCK SPIN',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Confetti
            if (_reward != null)
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
                        AppColors.accent3,
                      ],
                      numberOfParticles: 50,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<int> rewards;
  final List<Color> colors;

  _WheelPainter({required this.rewards, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectorAngle = 2 * pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      final startAngle = i * sectorAngle - pi / 2;

      // Draw sector
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectorAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectorAngle,
        true,
        borderPaint,
      );

      // Draw text
      final textAngle = startAngle + sectorAngle / 2;
      const textRadius = 95.0;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '+${rewards[i]}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
