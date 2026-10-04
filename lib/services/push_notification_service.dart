import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/device_token_api.dart';

class PushNotificationService {
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _authToken;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _firebaseReady = false;
  bool _localReady = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'signals',
    'Signals',
    description: 'Trading signal notifications',
    importance: Importance.high,
  );

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

    await _setupForegroundNotifications();

    if (_authToken != null) {
      await _syncCurrentToken();
    }
  }

  /// FCM does not display notifications while the app is in the foreground
  /// on Android, so show them locally. Background/terminated delivery is still
  /// handled by the system, so no duplicate is produced.
  Future<void> _setupForegroundNotifications() async {
    try {
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
      _localReady = true;
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
      );
    } catch (e) {
      debugPrint('PushNotificationService: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (!_localReady || notification == null) return;
    try {
      await _localNotifications.show(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('PushNotificationService: $e');
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
    _foregroundSubscription?.cancel();
  }
}
