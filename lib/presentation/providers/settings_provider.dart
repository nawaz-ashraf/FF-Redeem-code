// lib/presentation/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// Stream of app settings for real-time configuration updates
final appSettingsProvider = StreamProvider<AppSettingsModel>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchAppSettings();
});

/// Theme mode state (persisted in SharedPreferences)
final isDarkModeProvider = StateProvider<bool>((ref) => true);

/// Maintenance mode check
final isMaintenanceProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.whenOrNull(data: (s) => s.maintenanceMode) ?? false;
});
