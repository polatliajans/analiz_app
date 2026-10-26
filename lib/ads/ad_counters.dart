import 'package:shared_preferences/shared_preferences.dart';

const _analysisCountKey = 'ads_analysis_count';
const _lastInterstitialKey = 'ads_last_interstitial_ms';
const _chartVisitsKey = 'ads_chart_visits';
const _navDayKey = 'ads_nav_day';
const _navDayCountKey = 'ads_nav_day_count';

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

  int get chartVisitCount => _prefs.getInt(_chartVisitsKey) ?? 0;

  Future<int> incrementChartVisits() async {
    final next = chartVisitCount + 1;
    await _prefs.setInt(_chartVisitsKey, next);
    return next;
  }

  static String _dayOf(DateTime t) => '${t.year}-${t.month}-${t.day}';

  /// Navigation interstitials shown on the local day of [now].
  int navigationShownToday(DateTime now) =>
      _prefs.getString(_navDayKey) == _dayOf(now)
      ? _prefs.getInt(_navDayCountKey) ?? 0
      : 0;

  /// Records a shown navigation interstitial: bumps today's count (reset on a
  /// new day) and the shared last-interstitial time.
  Future<void> recordNavigationShown(DateTime now) async {
    final count = navigationShownToday(now) + 1;
    await _prefs.setString(_navDayKey, _dayOf(now));
    await _prefs.setInt(_navDayCountKey, count);
    await setLastInterstitialAt(now);
  }
}
