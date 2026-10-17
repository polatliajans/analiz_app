import 'package:shared_preferences/shared_preferences.dart';

const _analysisCountKey = 'ads_analysis_count';
const _lastInterstitialKey = 'ads_last_interstitial_ms';

/// Persistent interstitial bookkeeping: successful analysis count and the
/// time the last interstitial was shown.
class AdCounters {
  final SharedPreferences _prefs;
  AdCounters(this._prefs);

  int get analysisCount => _prefs.getInt(_analysisCountKey) ?? 0;

  DateTime? get lastInterstitialAt {
    final ms = _prefs.getInt(_lastInterstitialKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<int> incrementAnalysisCount() async {
    final next = analysisCount + 1;
    await _prefs.setInt(_analysisCountKey, next);
    return next;
  }

  Future<void> setLastInterstitialAt(DateTime time) =>
      _prefs.setInt(_lastInterstitialKey, time.millisecondsSinceEpoch);
}
