import 'package:kriptoanaliz/services/analytics_service.dart';

/// Records every backend call; optionally throws from all of them.
class FakeAnalyticsBackend implements AnalyticsBackend {
  final bool throws;
  final calls = <String>[];
  final events = <({String name, Map<String, Object> params})>[];
  final screens = <String>[];
  final consents = <AnalyticsConsent>[];
  bool? collectionEnabled;
  String? userId;
  final userProperties = <String, String?>{};
  int resets = 0;

  FakeAnalyticsBackend({this.throws = false});

  Future<void> _call(String name) async {
    calls.add(name);
    if (throws) throw StateError('backend failure');
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
    await _call('collection');
  }

  @override
  Future<void> setConsent(AnalyticsConsent consent) async {
    consents.add(consent);
    await _call('consent');
  }

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    events.add((name: name, params: params));
    await _call('event');
  }

  @override
  Future<void> logScreenView(String screenName) async {
    screens.add(screenName);
    await _call('screen');
  }

  @override
  Future<void> setUserId(String? id) async {
    userId = id;
    await _call('userId');
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    userProperties[name] = value;
    await _call('property');
  }

  @override
  Future<void> resetAnalyticsData() async {
    resets++;
    await _call('reset');
  }
}

/// Records service-level calls (for tests of code that only uses the
/// [AnalyticsService] interface).
class RecordingAnalyticsService implements AnalyticsService {
  final events = <({String name, Map<String, Object?> params})>[];
  final screens = <String>[];
  final consents = <bool>[];
  String? userId;
  final properties = <String, String?>{};
  int accountResets = 0;

  @override
  bool get active => true;
  @override
  Future<void> init() async {}
  @override
  Future<void> applyConsent({required bool allowed}) async =>
      consents.add(allowed);
  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) =>
      events.add((name: name, params: params));
  @override
  void logScreenView(String screenName) => screens.add(screenName);
  @override
  void setUserId(String? id) => userId = id;
  @override
  void setUserProperty(String name, String? value) => properties[name] = value;
  @override
  Future<void> resetOnAccountDeleted() async => accountResets++;
}
