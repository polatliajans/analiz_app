import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';

const authPromptDoneKey = 'auth_prompt_done';

/// Whether the first-run sign-in screen has been dealt with (signed in or
/// continued as guest). Once true it is not shown again.
class AuthPromptDoneNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(authPromptDoneKey) ?? false;

  Future<void> complete() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(authPromptDoneKey, true);
  }

  /// Shows the first-run sign-in screen again (used after account deletion).
  Future<void> reset() async {
    state = false;
    await ref.read(sharedPreferencesProvider).setBool(authPromptDoneKey, false);
  }
}

final authPromptDoneProvider = NotifierProvider<AuthPromptDoneNotifier, bool>(
  AuthPromptDoneNotifier.new,
);
