import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/deep_analysis_api.dart';
import 'package:kriptoanaliz/models/ai_analysis_result.dart';
import 'package:kriptoanaliz/models/deep_analysis_job.dart';
import 'package:kriptoanaliz/services/deep_analysis_poller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemStore implements ActiveJobStore {
  int? id;
  @override
  int? read() => id;
  @override
  Future<void> save(int jobId) async => id = jobId;
  @override
  Future<void> clear() async => id = null;
}

DeepAnalysisJob _job(DeepAnalysisJobStatus s, {int id = 7}) =>
    DeepAnalysisJob(id: id, status: s, creditBalance: 80);

/// Fake clock: every delay advances time instead of waiting.
class _Harness {
  final start = DateTime(2026, 1, 1);
  late DateTime time = start;
  final delays = <Duration>[];
  final store = _MemStore();
  final seen = <DeepAnalysisJob>[];

  DeepAnalysisPoller poller(
    FetchJob fetch, {
    Duration maxDuration = const Duration(minutes: 8),
  }) => DeepAnalysisPoller(
    fetch: fetch,
    store: store,
    maxDuration: maxDuration,
    onJob: seen.add,
    now: () => time,
    delay: (d) async {
      delays.add(d);
      time = time.add(d);
    },
  );
}

void main() {
  test('polls every 3 s until completed, clears the stored id', () async {
    final h = _Harness();
    h.store.id = 7;
    final queue = [
      _job(DeepAnalysisJobStatus.queued),
      _job(DeepAnalysisJobStatus.running),
      _job(DeepAnalysisJobStatus.completed),
    ];
    final outcome = await h.poller((_) async => queue.removeAt(0)).poll(7);
    expect(outcome, isA<PollCompleted>());
    expect(h.delays, [const Duration(seconds: 3), const Duration(seconds: 3)]);
    expect(h.store.id, isNull);
    expect(h.seen, hasLength(3));
  });

  test('failed job ends polling and clears the stored id', () async {
    final h = _Harness();
    h.store.id = 7;
    final outcome = await h
        .poller((_) async => _job(DeepAnalysisJobStatus.failed))
        .poll(7);
    expect(outcome, isA<PollFailed>());
    expect(h.store.id, isNull);
  });

  test('transient errors are tolerated and the counter resets', () async {
    final h = _Harness();
    var calls = 0;
    final outcome = await h.poller((_) async {
      calls++;
      if (calls <= 5) throw Exception('offline');
      if (calls == 6) return _job(DeepAnalysisJobStatus.running);
      if (calls <= 11) throw Exception('offline');
      return _job(DeepAnalysisJobStatus.completed);
    }).poll(7);
    expect(outcome, isA<PollCompleted>());
    expect(calls, 12);
  });

  test('gives up after 8 consecutive errors, keeps the stored id', () async {
    final h = _Harness();
    h.store.id = 7;
    var calls = 0;
    final outcome = await h.poller((_) async {
      calls++;
      throw Exception('offline');
    }).poll(7);
    expect(outcome, isA<PollGaveUp>());
    expect(calls, 8);
    expect(h.store.id, 7);
  });

  test('client-side cap stops polling, keeps the stored id', () async {
    final h = _Harness();
    h.store.id = 7;
    var calls = 0;
    final outcome = await h.poller((_) async {
      calls++;
      return _job(DeepAnalysisJobStatus.running);
    }).poll(7);
    expect(outcome, isA<PollTimedOut>());
    expect(h.time.difference(h.start).inMinutes, 8);
    expect(calls, greaterThan(100));
    expect(h.store.id, 7);
  });

  test('404 stops polling and clears the stored id', () async {
    final h = _Harness();
    h.store.id = 7;
    final outcome = await h
        .poller((_) async => throw DeepAnalysisJobNotFoundException())
        .poll(7);
    expect(outcome, isA<PollNotFound>());
    expect(h.store.id, isNull);
  });

  test('cancel stops the loop and keeps the stored id', () async {
    final h = _Harness();
    h.store.id = 7;
    late DeepAnalysisPoller p;
    p = h.poller((_) async {
      p.cancel();
      return _job(DeepAnalysisJobStatus.running);
    });
    expect(await p.poll(7), isA<PollCancelled>());
    expect(h.store.id, 7);
    expect(p.isPolling, isFalse);
  });

  test('persist:false leaves another stored job alone', () async {
    final h = _Harness();
    h.store.id = 9;
    final outcome = await h
        .poller((_) async => _job(DeepAnalysisJobStatus.completed))
        .poll(7, persist: false);
    expect(outcome, isA<PollCompleted>());
    expect(h.store.id, 9);
  });

  test('resumes from a persisted id (SharedPreferences store)', () async {
    SharedPreferences.setMockInitialValues({activeDeepAnalysisJobKey: 42});
    final store = PrefsActiveJobStore(await SharedPreferences.getInstance());
    expect(store.read(), 42);
    final fetched = <int>[];
    final poller = DeepAnalysisPoller(
      fetch: (id) async {
        fetched.add(id);
        return _job(DeepAnalysisJobStatus.completed, id: id);
      },
      store: store,
      now: DateTime.now,
      delay: (_) async {},
    );
    expect(await poller.poll(store.read()!), isA<PollCompleted>());
    expect(fetched, [42]);
    expect(store.read(), isNull);
    await poller.track(5);
    expect(store.read(), 5);
  });

  group('minimum waiting card time', () {
    test('instant completion is held until minDuration', () async {
      final h = _Harness();
      final outcome = await h
          .poller((_) async => _job(DeepAnalysisJobStatus.completed))
          .poll(7, minDuration: minWaitingCardDuration);
      expect(outcome, isA<PollCompleted>());
      expect(h.delays, [minWaitingCardDuration]);
      expect(h.time.difference(h.start), minWaitingCardDuration);
    });

    test('real analyses are not delayed beyond their real duration', () async {
      final h = _Harness();
      final queue = [
        _job(DeepAnalysisJobStatus.running),
        _job(DeepAnalysisJobStatus.completed),
      ];
      await h
          .poller((_) async => queue.removeAt(0))
          .poll(7, minDuration: minWaitingCardDuration);
      expect(h.delays, [const Duration(seconds: 3)]);
    });

    test('no minimum by default and failures are never held', () async {
      final h = _Harness();
      await h
          .poller((_) async => _job(DeepAnalysisJobStatus.completed))
          .poll(7);
      await h
          .poller((_) async => _job(DeepAnalysisJobStatus.failed))
          .poll(7, minDuration: minWaitingCardDuration);
      expect(h.delays, isEmpty);
    });

    test('minimum is about two seconds', () {
      expect(minWaitingCardDuration, const Duration(seconds: 2));
    });
  });

  group('job model', () {
    test('parses cached and generated_at', () {
      final job = DeepAnalysisJob.fromJson({
        'id': 1,
        'status': 'completed',
        'cached': true,
        'analysis': {
          'id': 2,
          'result': 'x',
          'credit_cost': 3,
          'generated_at': '2026-01-01T10:00:00Z',
        },
      });
      expect(job.cached, isTrue);
      expect(job.analysis!.generatedAt, DateTime.utc(2026, 1, 1, 10));
    });

    test('old format without the fields still parses', () {
      final job = DeepAnalysisJob.fromJson({
        'id': 1,
        'status': 'completed',
        'analysis': {'id': 2, 'result': 'x', 'credit_cost': 3},
      });
      expect(job.cached, isFalse);
      expect(job.analysis!.generatedAt, isNull);
    });

    test('garbage generated_at is ignored', () {
      final a = AiAnalysisResult.fromJson({
        'id': 2,
        'result': 'x',
        'credit_cost': 3,
        'generated_at': 'nope',
      });
      expect(a.generatedAt, isNull);
    });
  });
}
