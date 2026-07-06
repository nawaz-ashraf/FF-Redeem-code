// lib/presentation/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.auth.authStateChanges();
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      final userRepo = ref.watch(userRepositoryProvider);
      return userRepo.watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepo;

  AuthNotifier(this._authRepo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _authRepo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
    bool skipUniquenessCheck = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.registerUser(
        name: name,
        email: email,
        password: password,
        referralCode: referralCode,
        skipUniquenessCheck: skipUniquenessCheck,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.loginUser(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _authRepo.sendPasswordReset(email);
  }

  Future<void> signOut() async {
    try {
      // Clear all local storage caches
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();

      // Clear all Hive boxes without deleting the directory
      // Only delete from disk if we know the box names, or we can just clear opened boxes.
      // We will skip Hive complete deletion here to avoid breaking Hive.initFlutter state,
      // but if there are specific user boxes later, they should be cleared here.
    } catch (e) {
      // Ignore errors during local storage clearance to ensure signOut proceeds
      debugPrint('Error clearing local storage: $e');
    }

    await _authRepo.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
