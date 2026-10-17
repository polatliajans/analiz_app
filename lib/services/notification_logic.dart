import 'dart:convert';

/// Screens a push notification can open (`data.screen`).
enum NotificationScreen {
  none,
  profile,
  creditPackages,
  subscription,
  radar,
  alarms,
  chart,
}

class NotificationTarget {
  final NotificationScreen screen;
  final int? coinId;

  const NotificationTarget(this.screen, {this.coinId});

  /// Screens that only make sense for a signed-in member.
  bool get requiresLogin =>
      screen == NotificationScreen.creditPackages ||
      screen == NotificationScreen.subscription ||
      screen == NotificationScreen.alarms;

  @override
  bool operator ==(Object other) =>
      other is NotificationTarget &&
      other.screen == screen &&
      other.coinId == coinId;

  @override
  int get hashCode => Object.hash(screen, coinId);
}

const _screenByName = <String, NotificationScreen>{
  'none': NotificationScreen.none,
  'profile': NotificationScreen.profile,
  'credit_packages': NotificationScreen.creditPackages,
  'subscription': NotificationScreen.subscription,
  'radar': NotificationScreen.radar,
  'alarms': NotificationScreen.alarms,
  'chart': NotificationScreen.chart,
};

/// Turns an FCM `data` map into a navigation target. Unknown or missing
/// screens only open the app.
NotificationTarget resolveNotificationTarget(Map<String, dynamic> data) {
  final name = data['screen'];
  final screen = name is String ? _screenByName[name] : null;
  if (screen == null) return const NotificationTarget(NotificationScreen.none);
  if (screen != NotificationScreen.chart) return NotificationTarget(screen);
  final raw = data['coin_id'];
  final coinId = raw is num ? raw.toInt() : int.tryParse('${raw ?? ""}');
  return NotificationTarget(screen, coinId: coinId);
}

/// Local notifications carry the FCM `data` map as a JSON payload.
NotificationTarget resolveNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    return const NotificationTarget(NotificationScreen.none);
  }
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      return resolveNotificationTarget(Map<String, dynamic>.from(decoded));
    }
  } catch (_) {}
  return const NotificationTarget(NotificationScreen.none);
}

const notificationChannelIds = ['announcements', 'credits', 'signals', 'alerts'];
const defaultNotificationChannelId = 'announcements';

const _channelByCategory = <String, String>{
  'announcement': 'announcements',
  'announcements': 'announcements',
  'credit': 'credits',
  'credits': 'credits',
  'signal': 'signals',
  'signals': 'signals',
  'alert': 'alerts',
  'alerts': 'alerts',
};

/// Picks the Android channel for a foreground notification from the FCM
/// `channel_id`, `data.channel` or `data.category` (in that order).
String resolveChannelId(String? androidChannelId, Map<String, dynamic> data) {
  if (androidChannelId != null &&
      notificationChannelIds.contains(androidChannelId)) {
    return androidChannelId;
  }
  final channel = data['channel'];
  if (channel is String && notificationChannelIds.contains(channel)) {
    return channel;
  }
  final category = data['category'];
  if (category is String && _channelByCategory.containsKey(category)) {
    return _channelByCategory[category]!;
  }
  return defaultNotificationChannelId;
}

/// Whether to show the one-time explanation before asking for the system
/// notification permission.
bool decideNotificationPermissionPrompt({
  required bool loggedIn,
  required bool alreadyAsked,
  required bool permissionGranted,
}) => loggedIn && !alreadyAsked && !permissionGranted;
