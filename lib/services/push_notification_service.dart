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
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (_) {
      // Firebase henüz yapılandırılmadı (google-services.json eksik).
      // Push özellikleri sessizce devre dışı kalır, uygulamanın geri kalanı etkilenmez.
      return;
    }

    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

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
      // Firebase tam yapılandırılmamış veya izin reddedilmiş olabilir; yoksay.
      debugPrint('PushNotificationService: $e');
    }
  }

  Future<void> _registerToken(String fcmToken) async {
    final authToken = _authToken;
    if (authToken == null) return;

    try {
      await DeviceTokenApi().register(token: authToken, fcmToken: fcmToken, platform: 'android');
    } catch (e) {
      // Ücretsiz üye için 403 beklenir; ağ hataları da kritik değil, sessizce yoksayılır.
      debugPrint('PushNotificationService: $e');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
