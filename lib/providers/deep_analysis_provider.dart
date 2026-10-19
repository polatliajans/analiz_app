import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/deep_analysis_api.dart';
import '../l10n/app_l10n.dart';
import '../models/deep_analysis_job.dart';
import '../services/deep_analysis_poller.dart';
import 'auth_provider.dart';
import 'locale_provider.dart' show sharedPreferencesProvider;

enum DeepAnalysisPhase {
  idle,

  /// The start request is in flight.
  starting,

  /// The job is queued/running on the server and being polled.
  waiting,
  completed,
  failed,

  /// Client-side cap reached; the job may still be running.
  timedOut,

  /// Too many consecutive network errors; the job may still be running.
  networkLost,

  /// A one-off problem to show (e.g. opening a job from a push failed).
  error,
}

class DeepAnalysisState {
  final DeepAnalysisPhase phase;
  final DeepAnalysisJob? job;

  /// Extra text for the user (e.g. the server's 409 message).
  final String? message;

  const DeepAnalysisState({
    this.phase = DeepAnalysisPhase.idle,
    this.job,
    this.message,
  });

  bool get isBusy =>
      phase == DeepAnalysisPhase.starting || phase == DeepAnalysisPhase.waiting;
}

final deepAnalysisApiProvider = Provider<DeepAnalysisApi>(
  (ref) => DeepAnalysisApi(),
);

final activeJobStoreProvider = Provider<ActiveJobStore>(
  (ref) => PrefsActiveJobStore(ref.watch(sharedPreferencesProvider)),
);

/// Runs the deep-analysis job lifecycle: start, poll, resume, finish.
/// Insufficient credit / Pro-required / other start errors are rethrown from
/// [start] so the screen can reuse its existing dialogs.
class DeepAnalysisNotifier extends Notifier<DeepAnalysisState> {
  late final DeepAnalysisPoller _poller = DeepAnalysisPoller(
    store: ref.read(activeJobStoreProvider),
    fetch: (id) => ref
        .read(deepAnalysisApiProvider)
        .fetchDeepAnalysisJob(token: _token!, jobId: id),
    onJob: (job) {
      final balance = job.creditBalance;
      if (balance != null) {
        ref.read(authProvider.notifier).setCreditBalance(balance);
      }
    },
  );

  String? get _token => ref.read(authProvider).token;

  @override
  DeepAnalysisState build() => const DeepAnalysisState();

  Future<void> start({required int coinId, required String timeframe}) async {
    final token = _token;
    if (token == null || state.isBusy) return;
    state = const DeepAnalysisState(phase: DeepAnalysisPhase.starting);
    final DeepAnalysisJob job;
    try {
      job = await ref
          .read(deepAnalysisApiProvider)
          .startDeepAnalysis(
            token: token,
            coinId: coinId,
            timeframe: timeframe,
          );
    } on DeepAnalysisInProgressException catch (e) {
      // Resume the existing job when its id is known (persisted).
      final existing = ref.read(activeJobStoreProvider).read();
      if (existing != null) {
        await _poll(existing, notice: e.message);
      } else {
        state = DeepAnalysisState(
          phase: DeepAnalysisPhase.error,
          message: e.message,
        );
      }
      return;
    } catch (_) {
      state = const DeepAnalysisState();
      rethrow;
    }
    final balance = job.creditBalance;
    if (balance != null) {
      ref.read(authProvider.notifier).setCreditBalance(balance);
    }
    await _poller.track(job.id);
    await _poll(job.id);
  }

  /// Continues polling a persisted active job (screen open / app resume).
  Future<void> resume() async {
    if (_token == null || _poller.isPolling || state.isBusy) return;
    if (state.phase == DeepAnalysisPhase.completed ||
        state.phase == DeepAnalysisPhase.failed) {
      return; // result not yet shown to the user
    }
    final id = ref.read(activeJobStoreProvider).read();
    if (id == null) return;
    await _poll(id);
  }

  /// Stops polling while the app is in the background (the id stays stored).
  void pause() => _poller.cancel();

  /// Opens a specific job (push tap): shows its result, or keeps waiting.
  Future<void> openJob(int jobId) async {
    if (_token == null) return;
    _poller.cancel();
    await _poll(jobId, persist: false);
  }

  /// The UI has shown the outcome; go back to idle and pick up any stored job.
  void acknowledge() {
    state = const DeepAnalysisState();
    resume();
  }

  Future<void> _poll(int jobId, {bool persist = true, String? notice}) async {
    state = DeepAnalysisState(
      phase: DeepAnalysisPhase.waiting,
      message: notice,
    );
    final outcome = await _poller.poll(jobId, persist: persist);
    switch (outcome) {
      case PollCompleted(:final job):
        state = DeepAnalysisState(
          phase: DeepAnalysisPhase.completed,
          job: job,
        );
      case PollFailed(:final job):
        state = DeepAnalysisState(phase: DeepAnalysisPhase.failed, job: job);
      case PollGaveUp():
        state = const DeepAnalysisState(phase: DeepAnalysisPhase.networkLost);
      case PollTimedOut():
        state = const DeepAnalysisState(phase: DeepAnalysisPhase.timedOut);
      case PollNotFound():
        state = const DeepAnalysisState();
      case PollCancelled():
        // Superseded by another poll, or paused in the background. Only fall
        // back to idle when nothing newer took over.
        if (!_poller.isPolling && state.phase == DeepAnalysisPhase.waiting) {
          state = const DeepAnalysisState();
        }
    }
  }

  /// Friendly text for a failed job.
  String failureText() => AppL10n.current.deepAnalysisFailedRefunded;
}

final deepAnalysisProvider =
    NotifierProvider<DeepAnalysisNotifier, DeepAnalysisState>(
      DeepAnalysisNotifier.new,
    );
