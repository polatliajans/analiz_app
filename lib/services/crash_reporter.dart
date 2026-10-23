import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Minimal surface of the crash backend (Firebase Crashlytics in production).
/// Kept tiny so tests can fake it and no SDK type leaks into the app.
abstract class CrashBackend {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> recordFlutterFatal(FlutterErrorDetails details);
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  });
  Future<void> setKey(String key, Object value);
}

/// App-facing crash reporting API. Never throws; never carries personal data.
abstract class CrashReporter {
  /// Process-wide reporter; a no-op until `main` installs a real one, so unit
  /// and widget tests never touch Firebase.
  static CrashReporter instance = const NoopCrashReporter();

  Future<void> init({required bool enabled});
  void recordFlutterFatal(FlutterErrorDetails details);
  void recordFatal(Object error, StackTrace stack);
  void recordNonFatal(Object error, StackTrace stack, {String? reason});

  /// Coarse, non-personal context only.
  void setContext({
    String? appVersion,
    String? locale,
    String? screen,
    bool? loggedIn,
  });
}

class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();
  @override
  Future<void> init({required bool enabled}) async {}
  @override
  void recordFlutterFatal(FlutterErrorDetails details) {}
  @override
  void recordFatal(Object error, StackTrace stack) {}
  @override
  void recordNonFatal(Object error, StackTrace stack, {String? reason}) {}
  @override
  void setContext({
    String? appVersion,
    String? locale,
    String? screen,
    bool? loggedIn,
  }) {}
}

/// Delegates to a [CrashBackend], swallowing every backend failure.
class SafeCrashReporter implements CrashReporter {
  SafeCrashReporter(this._backend);
  final CrashBackend _backend;

  void _guard(Future<void> Function() action) {
    try {
      unawaited(action().catchError((Object _) {}));
    } catch (_) {
      // A crash reporter must never crash the app.
    }
  }

  @override
  Future<void> init({required bool enabled}) async {
    try {
      await _backend.setCollectionEnabled(enabled);
    } catch (_) {}
  }

  @override
  void recordFlutterFatal(FlutterErrorDetails details) =>
      _guard(() => _backend.recordFlutterFatal(details));

  @override
  void recordFatal(Object error, StackTrace stack) =>
      _guard(() => _backend.recordError(error, stack, fatal: true));

  @override
  void recordNonFatal(Object error, StackTrace stack, {String? reason}) =>
      _guard(
        () => _backend.recordError(error, stack, fatal: false, reason: reason),
      );

  @override
  void setContext({
    String? appVersion,
    String? locale,
    String? screen,
    bool? loggedIn,
  }) {
    if (appVersion != null) {
      _guard(() => _backend.setKey('app_version', appVersion));
    }
    if (locale != null) _guard(() => _backend.setKey('locale', locale));
    if (screen != null) _guard(() => _backend.setKey('screen', screen));
    if (loggedIn != null) _guard(() => _backend.setKey('logged_in', loggedIn));
  }
}

/// Wires the global error hooks to [reporter]. The previous Flutter handler is
/// kept so console output still works.
void installCrashHandlers(CrashReporter reporter) {
  final previousFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    previousFlutter?.call(details);
    reporter.recordFlutterFatal(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.recordFatal(error, stack);
    return true;
  };
}

/// Non-personal description of an API failure: no URL query/host, no body.
class ApiFailure implements Exception {
  ApiFailure(this.kind, {this.status, this.path});
  final String kind;
  final int? status;
  final String? path;

  @override
  String toString() =>
      'ApiFailure($kind${status != null ? ' $status' : ''}'
      '${path != null ? ' $path' : ''})';
}

/// Reports an unexpected API-layer exception. Connectivity errors are ignored;
/// only the path (no query, host, message or body) is recorded.
void reportApiException(Uri uri, Object error, StackTrace stack) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is HttpException) {
    return;
  }
  // package:http's ClientException wraps network failures and embeds the URL.
  if (error.runtimeType.toString() == 'ClientException') return;
  CrashReporter.instance.recordNonFatal(
    ApiFailure('exception:${error.runtimeType}', path: uri.path),
    stack,
    reason: 'api_exception',
  );
}

/// Only server faults (5xx) are reported; 4xx are normal business outcomes
/// (402/403/409/429 ...).
void reportApiStatus(Uri uri, int status) {
  if (status < 500) return;
  CrashReporter.instance.recordNonFatal(
    ApiFailure('server_error', status: status, path: uri.path),
    StackTrace.current,
    reason: 'api_5xx',
  );
}
