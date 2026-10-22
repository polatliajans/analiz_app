import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ad_analysis_flow.dart';
import 'package:kriptoanaliz/ads/ad_logic.dart';
import 'package:kriptoanaliz/data/ad_analysis_api.dart';
import 'package:kriptoanaliz/models/ai_analysis_result.dart';

class FakeAdApi implements AdAnalysisApi {
  Object? createError;
  final List<Object> pollScript; // AdSessionState or Exception, consumed in order
  int creates = 0;
  int polls = 0;

  FakeAdApi({this.createError, this.pollScript = const []});

  @override
  Future<AdAnalysisStatus> fetchStatus(String token) async =>
      const AdAnalysisStatus();

  @override
  Future<AdAnalysisSession> createSession(String token) async {
    creates++;
    if (createError != null) throw createError!;
    return const AdAnalysisSession(id: 'sess-1', remainingToday: 4);
  }

  @override
  Future<AdSessionState> fetchSession(String token, String sessionId) async {
    expect(sessionId, 'sess-1');
    final i = polls++;
    final step = i < pollScript.length
        ? pollScript[i]
        : (pollScript.isEmpty ? const AdSessionState() : pollScript.last);
    if (step is AdSessionState) return step;
    throw step;
  }
}

class FakeAds implements AdAnalysisAdService {
  bool ready;
  RewardedOutcome outcome;
  bool throwOnPrepare = false;
  String? shownWith;
  int shows = 0;

  FakeAds({this.ready = true, this.outcome = RewardedOutcome.earned});

  @override
  Future<bool> prepare() async {
    if (throwOnPrepare) throw StateError('boom');
    return ready;
  }

  @override
  Future<RewardedOutcome> show(String sessionId) async {
    shows++;
    shownWith = sessionId;
    return outcome;
  }
}

const _verified = AdSessionState(verified: true);
const _pending = AdSessionState();
const _result = AiAnalysisResult(id: 9, result: 'ok', creditCost: 0);

AdAnalysisException _ex(AdAnalysisError e) => AdAnalysisException(e);

void main() {
  late List<Duration> delays;
  late List<AdFlowPhase> phases;
  late List<String> analyzeCalls;

  setUp(() {
    delays = [];
    phases = [];
    analyzeCalls = [];
  });

  AdAnalysisFlow flow(
    FakeAdApi api,
    FakeAds ads, {
    List<Object> analyzeScript = const [],
  }) {
    var n = 0;
    return AdAnalysisFlow(
      api: api,
      ads: ads,
      token: 't',
      onPhase: phases.add,
      delay: (d) async => delays.add(d),
      analyze: (id) async {
        analyzeCalls.add(id);
        final i = n++;
        if (i < analyzeScript.length) {
          final step = analyzeScript[i];
          if (step is AiAnalysisResult) return step;
          throw step;
        }
        return _result;
      },
    );
  }

  test('success: session -> ad (custom data = session id) -> verified -> analysis', () async {
    final api = FakeAdApi(pollScript: [_pending, _pending, _verified]);
    final ads = FakeAds();
    final r = await flow(api, ads).run();

    expect(r.outcome, AdFlowOutcome.success);
    expect(r.analysis, same(_result));
    expect(ads.shownWith, 'sess-1');
    expect(analyzeCalls, ['sess-1']);
    expect(api.polls, 3);
    expect(delays, hasLength(2));
    expect(phases, [
      AdFlowPhase.preparing,
      AdFlowPhase.creatingSession,
      AdFlowPhase.showingAd,
      AdFlowPhase.verifying,
      AdFlowPhase.analyzing,
    ]);
  });

  test('ad closed without reward cancels quietly, nothing else runs', () async {
    final api = FakeAdApi();
    final r = await flow(api, FakeAds(outcome: RewardedOutcome.dismissed)).run();
    expect(r.outcome, AdFlowOutcome.cancelled);
    expect(api.polls, 0);
    expect(analyzeCalls, isEmpty);
  });

  test('ad cannot be prepared: no session is created', () async {
    final api = FakeAdApi();
    final r = await flow(api, FakeAds(ready: false)).run();
    expect(r.outcome, AdFlowOutcome.adUnavailable);
    expect(api.creates, 0);
  });

  test('prepare throwing is treated as unavailable', () async {
    final ads = FakeAds()..throwOnPrepare = true;
    final r = await flow(FakeAdApi(), ads).run();
    expect(r.outcome, AdFlowOutcome.adUnavailable);
  });

  test('ad fails to show: friendly unavailable result', () async {
    for (final o in [RewardedOutcome.failed, RewardedOutcome.unavailable]) {
      final r = await flow(FakeAdApi(), FakeAds(outcome: o)).run();
      expect(r.outcome, AdFlowOutcome.adUnavailable);
      expect(analyzeCalls, isEmpty);
    }
  });

  test('verification never arrives: times out after maxPolls', () async {
    final api = FakeAdApi(pollScript: [_pending]);
    final r = await flow(api, FakeAds()).run();
    expect(r.outcome, AdFlowOutcome.verificationTimeout);
    expect(api.polls, 15);
    expect(analyzeCalls, isEmpty);
  });

  test('poll network errors are tolerated', () async {
    final api = FakeAdApi(pollScript: [Exception('net'), _verified]);
    final r = await flow(api, FakeAds()).run();
    expect(r.outcome, AdFlowOutcome.success);
  });

  test('expired/used session while polling', () async {
    final api = FakeAdApi(
      pollScript: [const AdSessionState(expired: true)],
    );
    final r = await flow(api, FakeAds()).run();
    expect(r.outcome, AdFlowOutcome.sessionExpired);
  });

  test('409 ad_not_verified is retried, then succeeds', () async {
    final api = FakeAdApi(pollScript: [_verified]);
    final r = await flow(
      api,
      FakeAds(),
      analyzeScript: [
        _ex(AdAnalysisError.notVerified),
        _ex(AdAnalysisError.notVerified),
        _result,
      ],
    ).run();
    expect(r.outcome, AdFlowOutcome.success);
    expect(analyzeCalls, ['sess-1', 'sess-1', 'sess-1']);
  });

  test('409 forever ends in verificationTimeout after the retries', () async {
    final api = FakeAdApi(pollScript: [_verified]);
    final r = await flow(
      api,
      FakeAds(),
      analyzeScript: List.generate(10, (_) => _ex(AdAnalysisError.notVerified)),
    ).run();
    expect(r.outcome, AdFlowOutcome.verificationTimeout);
    expect(analyzeCalls, hasLength(5)); // 1 try + 4 retries
  });

  group('error mapping', () {
    final fromAnalysis = {
      AdAnalysisError.sessionExpired: AdFlowOutcome.sessionExpired, // 410
      AdAnalysisError.capReached: AdFlowOutcome.capReached, // 429
      AdAnalysisError.hasCredit: AdFlowOutcome.hasCredit, // 422
      AdAnalysisError.notFree: AdFlowOutcome.notFree, // 403
      AdAnalysisError.emailUnverified: AdFlowOutcome.emailUnverified, // 403
      AdAnalysisError.disabled: AdFlowOutcome.disabled, // 403
    };

    fromAnalysis.forEach((error, outcome) {
      test('analysis $error -> $outcome', () async {
        final r = await flow(
          FakeAdApi(pollScript: [_verified]),
          FakeAds(),
          analyzeScript: [_ex(error)],
        ).run();
        expect(r.outcome, outcome);
        expect(analyzeCalls, hasLength(1));
      });

      test('session creation $error -> $outcome (no ad shown)', () async {
        final ads = FakeAds();
        final r = await flow(
          FakeAdApi(createError: _ex(error)),
          ads,
        ).run();
        expect(r.outcome, outcome);
        expect(ads.shows, 0);
      });
    });

    test('unrelated analysis error is failed with the error attached', () async {
      final boom = Exception('x');
      final r = await flow(
        FakeAdApi(pollScript: [_verified]),
        FakeAds(),
        analyzeScript: [boom],
      ).run();
      expect(r.outcome, AdFlowOutcome.failed);
      expect(r.error, boom);
    });

    test('unrelated session creation error is failed', () async {
      final r = await flow(
        FakeAdApi(createError: Exception('net')),
        FakeAds(),
      ).run();
      expect(r.outcome, AdFlowOutcome.failed);
    });
  });
}
