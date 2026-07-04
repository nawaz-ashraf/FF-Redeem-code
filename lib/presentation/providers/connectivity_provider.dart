// lib/presentation/providers/connectivity_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connectivity_service.dart';

/// Provides a stream of connectivity status (true = online)
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.onConnectivityChanged;
});

/// Current connectivity status
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.whenOrNull(data: (val) => val) ?? true;
});
