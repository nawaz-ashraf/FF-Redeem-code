// lib/core/animations/animations.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_theme.dart';

/// Coin count-up animation widget
class CoinCountUpAnimation extends StatefulWidget {
  final int targetValue;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  const CoinCountUpAnimation({
    super.key,
    required this.targetValue,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<CoinCountUpAnimation> createState() => _CoinCountUpAnimationState();
}

class _CoinCountUpAnimationState extends State<CoinCountUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = IntTween(begin: 0, end: widget.targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Text(
        '${widget.prefix}${_animation.value}${widget.suffix}',
        style: widget.style ??
            const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
            ),
      ),
    );
  }
}

/// Reward popup dialog with animation
class RewardPopup extends StatelessWidget {
  final int coins;
  final String title;
  final String subtitle;
  final VoidCallback? onDismiss;

  const RewardPopup({
    super.key,
    required this.coins,
    this.title = 'Congratulations! 🎉',
    this.subtitle = 'You earned coins!',
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E2A42), Color(0xFF0F1A32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            CoinCountUpAnimation(
              targetValue: coins,
              prefix: '+',
              suffix: ' Coins',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDismiss?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Awesome! 🎉',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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

/// Tick (success) animation widget
class TickAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const TickAnimation({
    super.key,
    this.size = 60,
    this.color = AppColors.success,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<TickAnimation> createState() => _TickAnimationState();
}

class _TickAnimationState extends State<TickAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.15),
          border: Border.all(color: widget.color, width: 3),
        ),
        child: Icon(
          Icons.check_rounded,
          color: widget.color,
          size: widget.size * 0.6,
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
