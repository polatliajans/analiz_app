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
}

final authPromptDoneProvider = NotifierProvider<AuthPromptDoneNotifier, bool>(
  AuthPromptDoneNotifier.new,
);
