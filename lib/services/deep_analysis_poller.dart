import 'package:shared_preferences/shared_preferences.dart';

import '../data/deep_analysis_api.dart';
import '../models/deep_analysis_job.dart';

/// Remembers the id of the deep-analysis job that is still running so polling
/// can resume after the screen was left or the app was restarted.
abstract class ActiveJobStore {
  int? read();
  Future<void> save(int jobId);
  Future<void> clear();
}

const activeDeepAnalysisJobKey = 'active_deep_analysis_job_id';

class PrefsActiveJobStore implements ActiveJobStore {
  final SharedPreferences _prefs;
  PrefsActiveJobStore(this._prefs);

  @override
  int? read() => _prefs.getInt(activeDeepAnalysisJobKey);

  @override
  Future<void> save(int jobId) async {
    await _prefs.setInt(activeDeepAnalysisJobKey, jobId);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(activeDeepAnalysisJobKey);
  }
}

sealed class PollOutcome {
  const PollOutcome();
}

class PollCompleted extends PollOutcome {
  final DeepAnalysisJob job;
  const PollCompleted(this.job);
}

class PollFailed extends PollOutcome {
  final DeepAnalysisJob job;
  const PollFailed(this.job);
}

/// Too many consecutive network errors: the job may still be running.
class PollGaveUp extends PollOutcome {
  const PollGaveUp();
}

/// Client-side time cap reached: the job may still be running.
class PollTimedOut extends PollOutcome {
  const PollTimedOut();
}

class PollCancelled extends PollOutcome {
  const PollCancelled();
}

class PollNotFound extends PollOutcome {
  const PollNotFound();
}

typedef FetchJob = Future<DeepAnalysisJob> Function(int jobId);

/// Polls a deep-analysis job until it finishes. Clock and delay are
/// injectable so tests run without real timers.
class DeepAnalysisPoller {
  final FetchJob fetch;
  final ActiveJobStore store;
  final Future<void> Function(Duration) delay;
  final DateTime Function() now;
  final Duration interval;
  final Duration maxDuration;
  final int maxConsecutiveErrors;

  /// Called with every successfully fetched job (e.g. to refresh the balance).
  final void Function(DeepAnalysisJob job)? onJob;

  DeepAnalysisPoller({
    required this.fetch,
    required this.store,
    this.onJob,
    Future<void> Function(Duration)? delay,
    DateTime Function()? now,
    this.interval = const Duration(seconds: 3),
    this.maxDuration = const Duration(minutes: 8),
    this.maxConsecutiveErrors = 8,
  }) : delay = delay ?? Future<void>.delayed,
       now = now ?? DateTime.now;

  int _generation = 0;
  int _active = 0;
  bool _cancelled = false;

  /// True while a poll loop is running and has not been cancelled.
  bool get isPolling => _active > 0 && !_cancelled;

  /// Stops running loops at their next iteration (the persisted id is kept).
  void cancel() {
    _generation++;
    _cancelled = true;
  }

  /// Persists [jobId] as the active job (call right after it was started).
  Future<void> track(int jobId) => store.save(jobId);

  /// Polls until a terminal state. With [persist] false (opening an old job
  /// from a push) the stored active id is left alone.
  Future<PollOutcome> poll(int jobId, {bool persist = true}) async {
    final generation = ++_generation;
    _cancelled = false;
    _active++;
    final started = now();
    var errors = 0;
    try {
      while (true) {
        if (generation != _generation) return const PollCancelled();
        try {
          final job = await fetch(jobId);
          errors = 0;
          onJob?.call(job);
          if (job.status.isTerminal) {
            if (persist) await _clearIfCurrent(jobId);
            return job.status == DeepAnalysisJobStatus.completed
                ? PollCompleted(job)
                : PollFailed(job);
          }
        } on DeepAnalysisJobNotFoundException {
          if (persist) await _clearIfCurrent(jobId);
          return const PollNotFound();
        } catch (_) {
          errors++;
          if (errors >= maxConsecutiveErrors) return const PollGaveUp();
        }
        if (now().difference(started) >= maxDuration) {
          return const PollTimedOut();
        }
        await delay(interval);
      }
    } finally {
      _active--;
    }
  }

  Future<void> _clearIfCurrent(int jobId) async {
    if (store.read() == jobId) await store.clear();
  }
}
