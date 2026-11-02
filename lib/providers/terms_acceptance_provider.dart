import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/terms.dart';
import '../data/terms_acceptance_api.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../utils/platform_info.dart';
import 'auth_provider.dart';
import 'locale_provider.dart';

const termsAcceptedVersionKey = 'terms_accepted_version';
const termsAcceptedAtKey = 'terms_accepted_at';

/// `"<memberId>|<version>"` entries already reported to the server.
const termsSyncedKey = 'terms_synced';

/// The version users must have accepted. Overridable in tests.
final termsVersionProvider = Provider<String>((ref) => termsVersion);

/// Clock used for the acceptance timestamp. Overridable in tests.
final termsClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final termsAcceptanceApiProvider = Provider<TermsAcceptanceApi>(
  (ref) => const HttpTermsAcceptanceApi(),
);

/// Whether the user accepted the *current* [termsVersion] on this device
/// (stored locally, so guests are covered too). A version bump makes it false
/// again until the user accepts anew.
class TermsAcceptedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final version = ref.watch(termsVersionProvider);
    return ref
            .read(sharedPreferencesProvider)
            .getString(termsAcceptedVersionKey) ==
        version;
  }

  /// Stores the accepted version and moment (UTC), then opens the app.
  Future<void> accept() async {
    final version = ref.read(termsVersionProvider);
    final at = ref.read(termsClockProvider)().toUtc();
    final prefs = ref.read(sharedPreferencesProvider);
    try {
      await prefs.setString(termsAcceptedAtKey, at.toIso8601String());
      await prefs.setString(termsAcceptedVersionKey, version);
    } catch (_) {
      // Storage failed: the gate would reappear next launch, but this
      // session may continue.
    }
    state = true;
    ref.read(analyticsProvider).logTermsAccepted(version);
  }
}

final termsAcceptedProvider = NotifierProvider<TermsAcceptedNotifier, bool>(
  TermsAcceptedNotifier.new,
);

/// Reports the acceptance of the current version to the server once per
/// (member, version). Fire-and-forget: it never blocks the UI, and a failure
/// is simply retried on a later trigger (next sign-in / next launch).
///
/// Guests have no account, so for them the acceptance stays local only.
class TermsSyncNotifier extends Notifier<void> {
  bool _inFlight = false;

  @override
  void build() {
    ref.listen<int?>(
      authProvider.select((s) => s.isLoggedIn ? s.member?.id : null),
      (_, id) {
        if (id != null) unawaited(sync());
      },
      fireImmediately: true,
    );
    ref.listen<bool>(termsAcceptedProvider, (_, accepted) {
      if (accepted) unawaited(sync());
    });
  }

  /// Sends the acceptance if it is signed in, accepted and not yet reported.
  /// Returns true when the server has (now or earlier) confirmed it.
  Future<bool> sync() async {
    if (_inFlight) return false;
    final auth = ref.read(authProvider);
    final member = auth.member;
    final token = auth.token;
    if (member == null || token == null) return false;
    if (!ref.read(termsAcceptedProvider)) return false;

    final version = ref.read(termsVersionProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final key = '${member.id}|$version';
    final done = prefs.getStringList(termsSyncedKey) ?? const <String>[];
    if (done.contains(key)) return true;

    final stored = DateTime.tryParse(prefs.getString(termsAcceptedAtKey) ?? '');
    final acceptedAt = stored ?? ref.read(termsClockProvider)();

    _inFlight = true;
    try {
      await ref
          .read(termsAcceptanceApiProvider)
          .submit(
            token: token,
            version: version,
            acceptedAt: acceptedAt,
            platform: platformName(),
          );
      // Keep only entries of the current version so the list stays tiny.
      final kept = done.where((e) => e.endsWith('|$version')).toList()
        ..add(key);
      await prefs.setStringList(termsSyncedKey, kept);
      return true;
    } catch (_) {
      return false;
    } finally {
      _inFlight = false;
    }
  }
}

final termsSyncProvider = NotifierProvider<TermsSyncNotifier, void>(
  TermsSyncNotifier.new,
);
