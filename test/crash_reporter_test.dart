import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kriptoanaliz/data/api_http.dart';
import 'package:kriptoanaliz/services/crash_reporter.dart';

class _FakeBackend implements CrashBackend {
  _FakeBackend({this.failing = false});
  final bool failing;
  final calls = <String>[];
  final keys = <String, Object>{};
  final errors = <Object>[];

  Future<void> _maybeFail() async {
    if (failing) throw StateError('backend down');
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    calls.add('enabled:$enabled');
    await _maybeFail();
  }

  @override
  Future<void> recordFlutterFatal(FlutterErrorDetails details) async {
    calls.add('flutterFatal');
    await _maybeFail();
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) async {
    calls.add('error:fatal=$fatal:${reason ?? ''}');
    errors.add(error);
    await _maybeFail();
  }

  @override
  Future<void> setKey(String key, Object value) async {
    keys[key] = value;
    await _maybeFail();
  }
}

void main() {
  tearDown(() => CrashReporter.instance = const NoopCrashReporter());

  test('fatal handlers delegate to the backend', () async {
    final backend = _FakeBackend();
    final reporter = SafeCrashReporter(backend);
    await reporter.init(enabled: false);
    reporter.recordFlutterFatal(FlutterErrorDetails(exception: 'x'));
    reporter.recordFatal(StateError('boom'), StackTrace.current);
    reporter.recordNonFatal(
      StateError('soft'),
      StackTrace.current,
      reason: 'r',
    );
    expect(backend.calls, [
      'enabled:false',
      'flutterFatal',
      'error:fatal=true:',
      'error:fatal=false:r',
    ]);
  });

  test('only coarse non-personal context keys can be set', () {
    final backend = _FakeBackend();
    SafeCrashReporter(backend).setContext(
      appVersion: '1.0.0+1',
      locale: 'tr',
      screen: 'home',
      loggedIn: true,
    );
    expect(backend.keys, {
      'app_version': '1.0.0+1',
      'locale': 'tr',
      'screen': 'home',
      'logged_in': true,
    });
  });

  test('backend failures are swallowed', () async {
    final reporter = SafeCrashReporter(_FakeBackend(failing: true));
    await reporter.init(enabled: true);
    reporter.recordFlutterFatal(FlutterErrorDetails(exception: 'x'));
    reporter.recordFatal(StateError('a'), StackTrace.current);
    reporter.recordNonFatal(StateError('b'), StackTrace.current);
    reporter.setContext(screen: 'chart');
    await Future<void>.delayed(Duration.zero);
  });

  test('handlers installed delegate fatal errors', () {
    final backend = _FakeBackend();
    final prevFlutter = FlutterError.onError;
    final prevPlatform = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = prevFlutter;
      PlatformDispatcher.instance.onError = prevPlatform;
    });
    FlutterError.onError = (_) {};
    installCrashHandlers(SafeCrashReporter(backend));
    FlutterError.onError!(FlutterErrorDetails(exception: 'x'));
    final handled = PlatformDispatcher.instance.onError!(
      StateError('p'),
      StackTrace.current,
    );
    expect(handled, isTrue);
    expect(backend.calls, ['flutterFatal', 'error:fatal=true:']);
  });

  test('API reporting skips 4xx and network errors, strips URL details', () {
    final backend = _FakeBackend();
    CrashReporter.instance = SafeCrashReporter(backend);
    final uri = Uri.parse('https://x.test/api/me?token=SECRET123');

    reportApiStatus(uri, 402);
    reportApiStatus(uri, 403);
    reportApiStatus(uri, 409);
    reportApiStatus(uri, 429);
    reportApiException(
      uri,
      const SocketException('SECRET123'),
      StackTrace.empty,
    );
    reportApiException(uri, TimeoutException('t'), StackTrace.empty);
    reportApiException(
      uri,
      http.ClientException('fail', uri),
      StackTrace.empty,
    );
    expect(backend.errors, isEmpty);

    reportApiStatus(uri, 500);
    reportApiException(
      uri,
      const FormatException('SECRET123'),
      StackTrace.empty,
    );
    expect(backend.errors, hasLength(2));
    for (final e in backend.errors) {
      expect(e.toString(), isNot(contains('SECRET123')));
      expect(e.toString(), isNot(contains('x.test')));
      expect(e.toString(), contains('/api/me'));
    }
  });

  test('ApiHttp rethrows original errors untouched', () async {
    CrashReporter.instance = SafeCrashReporter(_FakeBackend());
    await expectLater(
      ApiHttp.get(Uri.parse('http://127.0.0.1:1/none')),
      throwsA(anything),
    );
  });
}
