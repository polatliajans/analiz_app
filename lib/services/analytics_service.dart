import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Analytics hard limits (see the Firebase docs); the service
/// enforces them so a bad call can never make the SDK throw.
const analyticsMaxEventNameLength = 40;
const analyticsMaxParams = 25;
const analyticsMaxParamNameLength = 40;
const analyticsMaxParamValueLength = 100;
const analyticsMaxUserPropertyNameLength = 24;
const analyticsMaxUserPropertyValueLength = 36;

/// Events held back while the consent decision is still pending.
const analyticsMaxQueuedEvents = 50;

/// Consent as handed to the SDK. Only analytics storage is ever granted;
/// advertising consent types stay denied (analytics is not used for ads).
class AnalyticsConsent {
  final bool analyticsStorage;
  final bool adStorage;
  final bool adUserData;
  final bool adPersonalization;

  const AnalyticsConsent({
    required this.analyticsStorage,
    this.adStorage = false,
    this.adUserData = false,
    this.adPersonalization = false,
  });

  /// Maps the user's analytics decision to the consent types.
  factory AnalyticsConsent.forDecision({required bool allowed}) =>
      AnalyticsConsent(analyticsStorage: allowed);
}

/// Minimal surface of the analytics SDK. Kept tiny so tests can fake it and
/// no SDK type leaks into the app.
abstract class AnalyticsBackend {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> setConsent(AnalyticsConsent consent);
  Future<void> logEvent(String name, Map<String, Object> params);
  Future<void> logScreenView(String screenName);
  Future<void> setUserId(String? id);
  Future<void> setUserProperty(String name, String? value);
  Future<void> resetAnalyticsData();
}

/// App-facing analytics API. Never throws and never blocks the caller; carries
/// no personal data (no email, no name) by contract.
abstract class AnalyticsService {
  /// False for the no-op default (tests, Firebase unavailable, debug builds):
  /// consent handling can then skip the UMP calls entirely.
  bool get active;

  /// Starts denied: no collection until [applyConsent] says otherwise.
  Future<void> init();

  /// Applies the user's analytics decision. Granting flushes the events that
  /// were queued while undecided; denying drops them.
  Future<void> applyConsent({required bool allowed});

  void logEvent(String name, [Map<String, Object?> params = const {}]);
  void logScreenView(String screenName);

  /// Sets the member numeric id (never an email or name); null clears it.
  void setUserId(String? id);

  /// Sets a user property; a null value clears it.
  void setUserProperty(String name, String? value);

  /// Account deletion: forget the identity and wipe the app instance data.
  Future<void> resetOnAccountDeleted();
}

class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();
  @override
  bool get active => false;
  @override
  Future<void> init() async {}
  @override
  Future<void> applyConsent({required bool allowed}) async {}
  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {}
  @override
  void logScreenView(String screenName) {}
  @override
  void setUserId(String? id) {}
  @override
  void setUserProperty(String name, String? value) {}
  @override
  Future<void> resetOnAccountDeleted() async {}
}

final _eventNamePattern = RegExp(r'^[A-Za-z][A-Za-z0-9_]*$');
const _reservedPrefixes = ['firebase_', 'google_', 'ga_'];

/// True when [name] is usable as an event or parameter name.
bool isValidAnalyticsName(String name, {int maxLength = 40}) =>
    name.isNotEmpty &&
    name.length <= maxLength &&
    _eventNamePattern.hasMatch(name) &&
    !_reservedPrefixes.any(name.startsWith);

/// Drops null / unsupported values, converts booleans to 1/0 (the SDK only
/// accepts strings and numbers), truncates long strings and caps the count.
Map<String, Object> sanitizeAnalyticsParams(Map<String, Object?> params) {
  final out = <String, Object>{};
  for (final entry in params.entries) {
    if (out.length >= analyticsMaxParams) break;
    if (!isValidAnalyticsName(
      entry.key,
      maxLength: analyticsMaxParamNameLength,
    )) {
      continue;
    }
    final v = entry.value;
    if (v is String) {
      out[entry.key] = v.length > analyticsMaxParamValueLength
          ? v.substring(0, analyticsMaxParamValueLength)
          : v;
    } else if (v is bool) {
      out[entry.key] = v ? 1 : 0;
    } else if (v is int) {
      out[entry.key] = v;
    } else if (v is double && v.isFinite) {
      out[entry.key] = v;
    }
  }
  return out;
}

enum _Consent { pending, granted, denied }

/// Wraps an [AnalyticsBackend]: validates input, holds events until consent is
/// decided, and swallows every backend failure.
class SafeAnalyticsService implements AnalyticsService {
  final AnalyticsBackend _backend;
  _Consent _consent = _Consent.pending;
  final List<void Function()> _queue = [];
  String? _userId;
  final Map<String, String?> _properties = {};

  SafeAnalyticsService(this._backend);

  @override
  bool get active => true;

  /// Test hook: whether events are currently delivered immediately.
  bool get collecting => _consent == _Consent.granted;

  @override
  Future<void> init() async {
    _consent = _Consent.pending;
    await _guard(
      () => _backend.setConsent(AnalyticsConsent.forDecision(allowed: false)),
    );
    await _guard(() => _backend.setCollectionEnabled(false));
  }

  @override
  Future<void> applyConsent({required bool allowed}) async {
    final wasGranted = _consent == _Consent.granted;
    _consent = allowed ? _Consent.granted : _Consent.denied;
    await _guard(
      () => _backend.setConsent(AnalyticsConsent.forDecision(allowed: allowed)),
    );
    await _guard(() => _backend.setCollectionEnabled(allowed));
    if (allowed) {
      _applyIdentity();
      final pending = List.of(_queue);
      _queue.clear();
      for (final send in pending) {
        send();
      }
    } else {
      _queue.clear();
      if (wasGranted) await _guard(() => _backend.setUserId(null));
    }
  }

  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    if (!isValidAnalyticsName(name, maxLength: analyticsMaxEventNameLength)) {
      return;
    }
    final clean = sanitizeAnalyticsParams(params);
    _deliver(() => _fire(() => _backend.logEvent(name, clean)));
  }

  @override
  void logScreenView(String screenName) {
    if (screenName.isEmpty) return;
    final name = screenName.length > analyticsMaxParamValueLength
        ? screenName.substring(0, analyticsMaxParamValueLength)
        : screenName;
    _deliver(() => _fire(() => _backend.logScreenView(name)));
  }

  @override
  void setUserId(String? id) {
    _userId = id;
    if (_consent == _Consent.granted) {
      _fire(() => _backend.setUserId(id));
    }
  }

  @override
  void setUserProperty(String name, String? value) {
    if (!isValidAnalyticsName(
      name,
      maxLength: analyticsMaxUserPropertyNameLength,
    )) {
      return;
    }
    final v =
        value != null && value.length > analyticsMaxUserPropertyValueLength
        ? value.substring(0, analyticsMaxUserPropertyValueLength)
        : value;
    _properties[name] = v;
    if (_consent == _Consent.granted) {
      _fire(() => _backend.setUserProperty(name, v));
    }
  }

  @override
  Future<void> resetOnAccountDeleted() async {
    _userId = null;
    _properties.remove('plan');
    _queue.clear();
    if (_consent != _Consent.granted) return;
    await _guard(() => _backend.setUserId(null));
    await _guard(() => _backend.setUserProperty('plan', null));
    await _guard(_backend.resetAnalyticsData);
  }

  void _applyIdentity() {
    _fire(() => _backend.setUserId(_userId));
    _properties.forEach(
      (name, value) => _fire(() => _backend.setUserProperty(name, value)),
    );
  }

  /// Runs [send] now when granted, queues it while undecided, drops it when
  /// denied.
  void _deliver(void Function() send) {
    switch (_consent) {
      case _Consent.granted:
        send();
      case _Consent.pending:
        if (_queue.length >= analyticsMaxQueuedEvents) _queue.removeAt(0);
        _queue.add(send);
      case _Consent.denied:
        break;
    }
  }

  /// Fire-and-forget: a failing backend is ignored, never rethrown.
  void _fire(Future<void> Function() call) {
    try {
      unawaited(call().catchError((Object _) {}));
    } catch (_) {}
  }

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {}
  }
}

/// The process-wide analytics service; a no-op until `main` overrides it, so
/// tests never need Firebase.
final analyticsProvider = Provider<AnalyticsService>(
  (ref) => const NoopAnalyticsService(),
);
