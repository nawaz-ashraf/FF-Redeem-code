// lib/presentation/pages/games/scratch_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reward_provider.dart';

class ScratchPage extends ConsumerStatefulWidget {
  const ScratchPage({super.key});

  @override
  ConsumerState<ScratchPage> createState() => _ScratchPageState();
}

class _ScratchPageState extends ConsumerState<ScratchPage>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late ConfettiController _confettiController;

  bool _isScratching = false;
  bool _isRevealed = false;
  int? _reward;
  int _scratchPercent = 0;
  List<Offset> _scratchedAreas = [];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isScratching = true);

    final reward = await ref
        .read(rewardNotifierProvider.notifier)
        .claimScratchReward();

    if (mounted) {
      if (reward != null) {
        setState(() {
          _reward = reward;
          _isRevealed = true;
          _isScratching = false;
        });
        _confettiController.play();
      } else {
        setState(() => _isScratching = false);
        final error = ref.read(rewardNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Could not claim scratch reward'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleScratch(DragUpdateDetails details) {
    if (_isRevealed) return;
    setState(() {
      _scratchedAreas.add(details.localPosition);
      _scratchPercent = (_scratchedAreas.length * 100 ~/ 300).clamp(0, 100);
    });

    if (_scratchPercent >= 60 && !_isRevealed && !_isScratching) {
      _claimReward();
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
                          '🎴 Scratch & Win',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Remaining count
                  FutureBuilder<Map<String, int>>(
                    future: ref.read(rewardRepositoryProvider).getDailyLimits(
                          ref.read(currentUserProvider).value?.uid ?? '',
                        ),
                    builder: (context, snap) {
                      final remaining = snap.data?['scratchRemaining'] ?? AppConstants.maxDailyScratch;
                      return Text(
                        '$remaining card${remaining != 1 ? 's' : ''} remaining today',
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

                  // Scratch card
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_shakeAnimation.value * 0.3, 0),
                      child: child,
                    ),
                    child: GestureDetector(
                      onPanUpdate: _handleScratch,
                      onTap: _isRevealed
                          ? null
                          : () {
                              _shakeController.forward(from: 0);
                            },
                      child: _buildScratchCard(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Instructions or result
                  if (!_isRevealed)
                    Column(
                      children: [
                        Text(
                          'Scratch the card above to reveal your reward!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Possible rewards: ${AppConstants.scratchRewards.map((r) => '+$r').join(', ')} coins',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'You won $_reward coins! 🎉',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold,
                          ),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isRevealed = false;
                              _reward = null;
                              _scratchedAreas = [];
                              _scratchPercent = 0;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                          ),
                          child: const Text('Scratch Another Card'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Confetti
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
                    numberOfParticles: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScratchCard() {
    return Stack(
      children: [
        // Revealed reward
        Container(
          width: 280,
          height: 200,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  _reward != null ? '+$_reward' : '?',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'COINS',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Scratch overlay
        if (!_isRevealed)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CustomPaint(
              size: const Size(280, 200),
              painter: _ScratchPainter(scratchedAreas: _scratchedAreas),
              child: Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.white.withOpacity(0.7),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap & Scratch to Reveal',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _scratchPercent / 100,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Loading overlay
        if (_isScratching)
          Container(
            width: 280,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final List<Offset> scratchedAreas;

  _ScratchPainter({required this.scratchedAreas});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    for (final offset in scratchedAreas) {
      canvas.drawCircle(offset, 25, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter old) {
    return old.scratchedAreas.length != scratchedAreas.length;
  }
}
