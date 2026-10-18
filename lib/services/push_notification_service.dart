import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/device_token_api.dart';
import '../l10n/app_l10n.dart';
import 'notification_logic.dart';

class PushNotificationService {
  /// Called when the user taps a notification that points somewhere
  /// (`data.screen` other than `none`).
  final void Function(NotificationTarget target)? onTarget;

  PushNotificationService({this.onTarget});

  static const _systemChannel = MethodChannel('kriptoanaliz/system');

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _authToken;
  String? _syncedAuthToken;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _firebaseReady = false;
  bool _localReady = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  Future<void> initialize() async {
    await _setupLocalNotifications();

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
    // FCM does not display notifications while the app is in the foreground
    // on Android, so show them locally. Background/terminated delivery is
    // still handled by the system, so no duplicate is produced.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _emit(resolveNotificationTarget(message.data)),
    );

    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _emit(resolveNotificationTarget(initial.data));
    } catch (e) {
      debugPrint('PushNotificationService: $e');
    }

    if (_authToken != null) {
      await _syncCurrentToken();
    }
  }

  void _emit(NotificationTarget target) {
    if (target.screen == NotificationScreen.none) return;
    onTarget?.call(target);
  }

  Future<void> _setupLocalNotifications() async {
    try {
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _emit(resolveNotificationPayload(response.payload)),
      );
      _localReady = true;
      await refreshChannels();

      final launch = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _emit(resolveNotificationPayload(launch!.notificationResponse?.payload));
      }
    } catch (e) {
      debugPrint('PushNotificationService: $e');
    }
  }

  /// (Re)creates the Android channels with names in the current app language.
  /// Re-creating an existing channel only updates its name and description.
  Future<void> refreshChannels() async {
    if (!_localReady) return;
    final l10n = AppL10n.current;
    final channels = [
      AndroidNotificationChannel(
        'announcements',
        l10n.notifChannelAnnouncementsName,
        description: l10n.notifChannelAnnouncementsDesc,
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'credits',
        l10n.notifChannelCreditsName,
        description: l10n.notifChannelCreditsDesc,
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'signals',
        l10n.notifChannelSignalsName,
        description: l10n.notifChannelSignalsDesc,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'alerts',
        l10n.notifChannelAlertsName,
        description: l10n.notifChannelAlertsDesc,
        importance: Importance.high,
      ),
    ];
    try {
      final android = _android;
      if (android == null) return;
      for (final channel in channels) {
        await android.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('PushNotificationService: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (!_localReady || notification == null) return;

    // Drop re-deliveries of a message that was already shown.
    final key = (message.data['push_id'] as String?) ?? message.messageId;
    if (!await _isNewMessage(key)) return;

    final channelId = resolveChannelId(
      notification.android?.channelId,
      message.data,
    );
    final l10n = AppL10n.current;
    final (name, description, high) = switch (channelId) {
      'credits' => (
        l10n.notifChannelCreditsName,
        l10n.notifChannelCreditsDesc,
        false,
      ),
      'signals' => (
        l10n.notifChannelSignalsName,
        l10n.notifChannelSignalsDesc,
        true,
      ),
      'alerts' => (
        l10n.notifChannelAlertsName,
        l10n.notifChannelAlertsDesc,
        true,
      ),
      _ => (
        l10n.notifChannelAnnouncementsName,
        l10n.notifChannelAnnouncementsDesc,
        false,
      ),
    };
    try {
      await _localNotifications.show(
        id: key != null && key.isNotEmpty
            ? stableNotificationId(key)
            : message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            name,
            channelDescription: description,
            importance: high ? Importance.high : Importance.defaultImportance,
            priority: high ? Priority.high : Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('PushNotificationService: $e');
    }
  }

  static const _seenMessagesKey = 'seen_push_message_ids';

  /// Records [key] as delivered; false when it was already shown before.
  Future<bool> _isNewMessage(String? key) async {
    if (key == null || key.isEmpty) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = rememberMessage(
        prefs.getStringList(_seenMessagesKey) ?? const <String>[],
        key,
      );
      if (result.isNew) {
        await prefs.setStringList(_seenMessagesKey, result.seen);
      }
      return result.isNew;
    } catch (_) {
      return true;
    }
  }

  /// Whether the system currently lets the app post notifications.
  Future<bool> notificationsEnabled() async {
    try {
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Shows the system permission dialog (Android 13+). Returns the result.
  Future<bool> requestPermission() async {
    try {
      return await _android?.requestNotificationsPermission() ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the app's notification page in the Android system settings.
  /// Returns false when that is not possible.
  Future<bool> openSystemNotificationSettings() async {
    try {
      return await _systemChannel.invokeMethod<bool>(
            'openNotificationSettings',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Any signed-in member gets a device token registered (no role check).
  void updateAuth({required String? authToken}) {
    if (authToken != _authToken) _syncedAuthToken = null;
    _authToken = authToken;
    if (_authToken != null && _firebaseReady) {
      _syncCurrentToken();
    }
  }

  Future<void> _syncCurrentToken() async {
    final authToken = _authToken;
    if (authToken == null || _syncedAuthToken == authToken) return;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && await _registerToken(fcmToken)) {
        _syncedAuthToken = authToken;
      }
    } catch (e) {
      // Firebase may be only partially configured; ignore.
      debugPrint('PushNotificationService: $e');
    }
  }

  Future<bool> _registerToken(String fcmToken) async {
    final authToken = _authToken;
    if (authToken == null) return false;

    try {
      await DeviceTokenApi().register(
        token: authToken,
        fcmToken: fcmToken,
        platform: 'android',
      );
      return true;
    } catch (e) {
      // Network errors are not critical and are ignored silently; the next
      // auth change or token refresh retries.
      debugPrint('PushNotificationService: $e');
      return false;
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
  }
}
