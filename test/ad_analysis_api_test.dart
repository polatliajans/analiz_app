import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kriptoanaliz/data/ad_analysis_api.dart';
import 'package:kriptoanaliz/data/ai_analysis_api.dart';
import 'package:kriptoanaliz/data/plan_errors.dart';
import 'package:kriptoanaliz/models/app_config.dart';

http.Response _err(int status, String code) =>
    http.Response(jsonEncode({'code': code, 'message': 'm'}), status);

void main() {
  group('app-config', () {
    test('parses ad_analysis_enabled and daily cap', () {
      final c = AppConfig.fromJson({
        'ad_analysis_enabled': true,
        'ad_analysis_daily_cap': 5,
      });
      expect(c.adAnalysisEnabled, isTrue);
      expect(c.adAnalysisDailyCap, 5);
    });

    test('missing keys default to false / 0', () {
      final c = AppConfig.fromJson({});
      expect(c.adAnalysisEnabled, isFalse);
      expect(c.adAnalysisDailyCap, 0);
      expect(AppConfig.safeDefaults.adAnalysisEnabled, isFalse);
    });

    test('tolerates the keys nested under ads', () {
      final c = AppConfig.fromJson({
        'ads': {'ad_analysis_enabled': true, 'ad_analysis_daily_cap': 3},
      });
      expect(c.adAnalysisEnabled, isTrue);
      expect(c.adAnalysisDailyCap, 3);
    });

    test('deep_analysis_requires_pro=false is honoured', () {
      final c = AppConfig.fromJson({
        'plan': {'deep_analysis_requires_pro': false},
      });
      expect(c.plan.deepAnalysisRequiresPro, isFalse);
    });
  });

  group('models', () {
    test('status', () {
      final s = AdAnalysisStatus.fromJson({
        'enabled': true,
        'daily_cap': 5,
        'used_today': 2,
        'remaining_today': 3,
        'eligible': true,
        'reason': null,
      });
      expect(s.eligible, isTrue);
      expect(s.remainingToday, 3);
      expect(s.reason, isNull);
      final off = AdAnalysisStatus.fromJson({
        'eligible': false,
        'reason': 'cap_reached',
      });
      expect(off.eligible, isFalse);
      expect(off.reason, 'cap_reached');
    });

    test('session and session state', () {
      final s = AdAnalysisSession.fromJson({
        'session_id': 'abc',
        'expires_at': '2026-10-23T10:00:00Z',
        'remaining_today': 4,
      });
      expect(s.id, 'abc');
      expect(s.remainingToday, 4);
      expect(s.expiresAt, isNotNull);
      final st = AdSessionState.fromJson({
        'verified': true,
        'used': false,
        'expired': false,
      });
      expect(st.verified, isTrue);
    });
  });

  group('session creation errors', () {
    final cases = {
      (403, 'not_free'): AdAnalysisError.notFree,
      (403, 'ad_analysis_disabled'): AdAnalysisError.disabled,
      (422, 'has_credit'): AdAnalysisError.hasCredit,
      (429, 'ad_analysis_cap_reached'): AdAnalysisError.capReached,
      (403, 'email_unverified'): AdAnalysisError.emailUnverified,
    };
    cases.forEach((key, expected) {
      test('${key.$1} ${key.$2}', () {
        expect(
          () => HttpAdAnalysisApi.parseSessionResponse(_err(key.$1, key.$2)),
          throwsA(
            isA<AdAnalysisException>().having((e) => e.error, 'error', expected),
          ),
        );
      });
    });

    test('201 is parsed', () {
      final s = HttpAdAnalysisApi.parseSessionResponse(
        http.Response(
          jsonEncode({
            'session_id': 'x',
            'expires_at': '2026-10-23T10:00:00Z',
            'remaining_today': 2,
          }),
          201,
        ),
      );
      expect(s.id, 'x');
    });
  });

  group('quick analysis response', () {
    const ok =
        '{"id":1,"result":"r","credit_cost":0}';

    test('200 parses', () {
      final r = AiAnalysisApi.parseResponse(
        http.Response(ok, 200),
        withAdSession: true,
      );
      expect(r.creditCost, 0);
    });

    test('ad errors map when an ad session was sent', () {
      final cases = {
        (409, 'ad_not_verified'): AdAnalysisError.notVerified,
        (410, 'ad_session_expired'): AdAnalysisError.sessionExpired,
        (422, 'has_credit'): AdAnalysisError.hasCredit,
        (429, 'ad_analysis_cap_reached'): AdAnalysisError.capReached,
        (403, 'email_unverified'): AdAnalysisError.emailUnverified,
      };
      cases.forEach((k, expected) {
        expect(
          () => AiAnalysisApi.parseResponse(
            _err(k.$1, k.$2),
            withAdSession: true,
          ),
          throwsA(
            isA<AdAnalysisException>().having((e) => e.error, 'error', expected),
          ),
        );
      });
    });

    test('402 stays InsufficientCreditException', () {
      expect(
        () => AiAnalysisApi.parseResponse(http.Response('{}', 402)),
        throwsA(isA<InsufficientCreditException>()),
      );
    });

    test('ad codes are not mapped without an ad session', () {
      expect(
        () => AiAnalysisApi.parseResponse(_err(409, 'ad_not_verified')),
        throwsA(isA<AiAnalysisException>()),
      );
    });
  });
}
