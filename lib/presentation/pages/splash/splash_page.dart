// lib/presentation/pages/splash/splash_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_update_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/update_dialog.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    debugPrint('Splash Loaded');
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // --- App update gate (see docs/APP_UPDATE.md) ---
    // Fetches Firestore config, compares versions, fails open on error.
    final updateStatus = await ref.read(appUpdateCheckProvider.future);
    if (!mounted) return;

    if (updateStatus != null && updateStatus.updateAvailable) {
      if (updateStatus.forceUpdate) {
        // Blocking: show dialog and stop — user cannot reach home/login.
        if (!context.mounted) return;
        await showUpdateDialog(context, updateStatus);
        return;
      }

      // Optional: user may tap "Later" to continue, or "Update" to open store.
      if (!context.mounted) return;
      final shouldContinue = await showUpdateDialog(context, updateStatus);
      if (!shouldContinue || !context.mounted) return;
    }

    await _continueNavigation();
  }

  /// Existing splash routing: home if logged in, else onboarding or login.
  Future<void> _continueNavigation() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;

    final isOnboardingDone =
        prefs.getBool(AppConstants.isOnboardingDoneKey) ?? false;

    final authState = ref.read(authStateProvider);

    if (authState.value != null) {
      context.go('/home');
    } else if (!isOnboardingDone) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0D16), Color(0xFF10131D), Color(0xFF1A1030)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              top: -100,
              right: -100,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) => Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(
                            0.15 + _glowController.value * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) => Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent1.withOpacity(
                            0.12 + _glowController.value * 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'FF',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1, 1),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      )
                      .fade(duration: 600.ms),
                  const SizedBox(height: 24),
                  // App name
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  )
                      .animate(delay: 400.ms)
                      .slideY(
                        begin: 0.5,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      )
                      .fade(duration: 600.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Earn Coins • Get Rewards',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  )
                      .animate(delay: 600.ms)
                      .slideY(
                        begin: 0.5,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      )
                      .fade(duration: 600.ms),
                  const SizedBox(height: 60),
                  // Loading indicator
                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        backgroundColor:
                            AppColors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  )
                      .animate(delay: 800.ms)
                      .fade(duration: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Rewards are subject to availability',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate(delay: 1000.ms)
                      .fade(duration: 400.ms),
                ],
              ),
            ),
            // Version
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Text(
                'v${AppConstants.appVersion}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ).animate(delay: 1200.ms).fade(duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}
