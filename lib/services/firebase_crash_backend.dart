import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

class FirebaseCrashBackend implements CrashBackend {
  FirebaseCrashlytics get _c => FirebaseCrashlytics.instance;

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _c.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> recordFlutterFatal(FlutterErrorDetails details) =>
      _c.recordFlutterFatalError(details);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) => _c.recordError(error, stack, fatal: fatal, reason: reason);

  @override
  Future<void> setKey(String key, Object value) => _c.setCustomKey(key, value);
}
