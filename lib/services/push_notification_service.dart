import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/device_token_api.dart';

class PushNotificationService {
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _authToken;
  bool _firebaseReady = false;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (_) {
      // Firebase is not configured yet (google-services.json is missing).
      // Push features are silently disabled; the rest of the app is unaffected.
      return;
    }

    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen(_registerToken);

    if (_authToken != null) {
      await _syncCurrentToken();
    }
  }

  void updateAuth({required String? authToken, required String? role}) {
    _authToken = (role == 'pro') ? authToken : null;
    if (_authToken != null && _firebaseReady) {
      _syncCurrentToken();
    }
  }

  Future<void> _syncCurrentToken() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _registerToken(fcmToken);
      }
    } catch (e) {
      // Firebase may be only partially configured or permission was denied; ignore.
      debugPrint('PushNotificationService: $e');
    }
  }

  Future<void> _registerToken(String fcmToken) async {
    final authToken = _authToken;
    if (authToken == null) return;

    try {
      await DeviceTokenApi().register(
        token: authToken,
        fcmToken: fcmToken,
        platform: 'android',
      );
    } catch (e) {
      // A 403 is expected for free members; network errors are not critical either and are ignored silently.
      debugPrint('PushNotificationService: $e');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
