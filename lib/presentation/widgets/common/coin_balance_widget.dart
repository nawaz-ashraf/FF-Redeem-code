// lib/presentation/widgets/common/coin_balance_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class CoinBalanceWidget extends StatelessWidget {
  final int coins;
  final double fontSize;
  final bool showIcon;

  const CoinBalanceWidget({
    super.key,
    required this.coins,
    this.fontSize = 18,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            const Text('🪙', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
          ],
          Text(
            coins.toString(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.3),
        );
  }
}
