// lib/core/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Monitors network connectivity and provides a reactive stream
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static final _controller = StreamController<bool>.broadcast();

  /// Whether the device currently has internet
  static bool _isConnected = true;
  static bool get isConnected => _isConnected;

  /// Stream of connectivity changes (true = connected, false = disconnected)
  static Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Initialize connectivity monitoring
  static Future<void> initialize() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _isConnected = !result.contains(ConnectivityResult.none);
    _controller.add(_isConnected);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final connected = !results.contains(ConnectivityResult.none);
      if (_isConnected != connected) {
        _isConnected = connected;
        _controller.add(_isConnected);
        debugPrint('Connectivity changed: ${_isConnected ? "Online" : "Offline"}');
      }
    });
  }

  /// Check current connectivity status
  static Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = !result.contains(ConnectivityResult.none);
    return _isConnected;
  }

  /// Dispose resources
  static void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
