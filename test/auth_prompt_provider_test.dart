import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kriptoanaliz/providers/auth_prompt_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  test('authPromptDoneProvider defaults to false', () async {
    final container = await _container({});
    addTearDown(container.dispose);
    expect(container.read(authPromptDoneProvider), isFalse);
  });

  test('complete() flips the flag and persists it', () async {
    final container = await _container({});
    addTearDown(container.dispose);
    await container.read(authPromptDoneProvider.notifier).complete();
    expect(container.read(authPromptDoneProvider), isTrue);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getBool(authPromptDoneKey), isTrue);
  });

  test('reads a previously stored flag', () async {
    final container = await _container({authPromptDoneKey: true});
    addTearDown(container.dispose);
    expect(container.read(authPromptDoneProvider), isTrue);
  });
}
