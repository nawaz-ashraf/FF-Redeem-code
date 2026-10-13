import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'core/services/app_check_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ad_service.dart';
import 'presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF10131D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Setup Crashlytics error handlers for both Flutter and asynchronous Dart errors
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true; // Prevents process termination
    };
  } catch (e, stack) {
    debugPrint('Firebase.initializeApp non-fatal error: $e\n$stack');
  }

  // Initialize App Check (Play Integrity in prod, Debug in dev)
  try {
    await AppCheckService.initialize();
  } catch (e) {
    debugPrint('AppCheckService non-fatal error: $e');
  }

  // Initialize Notifications
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('NotificationService non-fatal error: $e');
  }

  // Initialize Ads asynchronously
  try {
    AdService.initialize();
  } catch (e) {
    debugPrint('AdService non-fatal error: $e');
  }

  // Hive (for local storage if needed later)
  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint('Hive.initFlutter non-fatal error: $e');
  }

  debugPrint('App Started');
  runApp(const ProviderScope(child: FFRedeemApp()));
}

class FFRedeemApp extends ConsumerWidget {
  const FFRedeemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp.router(
      title: 'Game Redeem Code',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
