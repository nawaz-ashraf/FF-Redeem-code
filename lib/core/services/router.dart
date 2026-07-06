// lib/core/services/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/home/main_shell.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/redeem/redeem_page.dart';
import '../../presentation/pages/history/history_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/profile/privacy_policy_page.dart';
import '../../presentation/pages/profile/terms_page.dart';
import '../../presentation/pages/profile/faq_page.dart';
import '../../presentation/pages/games/scratch_page.dart';
import '../../presentation/pages/games/spin_page.dart';
import '../../presentation/pages/games/watch_ads_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/notifications/notifications_page.dart';
import '../../presentation/pages/admin/admin_dashboard.dart';
import '../../presentation/pages/admin/admin_redeem_codes_page.dart';
import '../../presentation/pages/admin/admin_user_detail_page.dart';
import '../../presentation/providers/auth_provider.dart';

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (previous, next) {
        if (!next.isLoading && next.hasValue) {
          if (next.value != null) {
            debugPrint('User Logged In');
          } else {
            debugPrint('User Logged Out');
          }
        }
        notifyListeners();
      },
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      
      // Ensure we don't redirect on empty AsyncLoading states
      if (authState.isLoading && !authState.hasValue) return null;

      final isLoggedIn = authState.value != null;
      final isGoingToAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/onboarding');
      final isGoingToSplash = state.matchedLocation == '/splash';

      if (isGoingToSplash) return null;
      if (!isLoggedIn && !isGoingToAuth) {
        debugPrint('Navigating To Login');
        return '/login';
      }
      if (isLoggedIn && isGoingToAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/redeem',
            builder: (context, state) => const RedeemPage(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/scratch',
        builder: (context, state) => const ScratchPage(),
      ),
      GoRoute(
        path: '/spin',
        builder: (context, state) => const SpinPage(),
      ),
      GoRoute(
        path: '/watch-ads',
        builder: (context, state) => const WatchAdsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: '/faq-help',
        builder: (context, state) => const FaqHelpPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'redeem-codes',
            builder: (context, state) => const AdminRedeemCodesPage(),
          ),
          GoRoute(
            path: 'user/:userId',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return AdminUserDetailPage(userId: userId);
            },
          ),
        ],
      ),
    ],
  );
});
