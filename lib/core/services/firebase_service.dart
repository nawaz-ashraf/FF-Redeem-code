// lib/core/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static User? get currentUser => auth.currentUser;
  static String? get currentUserId => auth.currentUser?.uid;

  // Analytics
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  static Future<void> logLogin() async {
    await analytics.logLogin(loginMethod: 'email');
  }

  static Future<void> logSignUp() async {
    await analytics.logSignUp(signUpMethod: 'email');
  }

  // Messaging
  static Future<String?> getFCMToken() async {
    try {
      return await messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  static Future<void> requestNotificationPermission() async {
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}
  }

  // Firestore helpers
  static CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  static DocumentReference<Map<String, dynamic>> document(String path) {
    return firestore.doc(path);
  }

  static Future<void> runTransaction(
    Future<void> Function(Transaction tx) action,
  ) async {
    await firestore.runTransaction((tx) async {
      await action(tx);
    });
  }
}
