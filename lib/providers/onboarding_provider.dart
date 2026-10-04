import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_api.dart';
import '../models/onboarding_slide.dart';
import 'locale_provider.dart';

const _doneKey = 'onboarding_done';

/// Slides from the server, or null when the request fails or returns nothing
/// (the screen then shows the built-in slides).
final onboardingSlidesProvider =
    FutureProvider.autoDispose<List<OnboardingSlide>?>((ref) async {
      try {
        final slides = await OnboardingApi().fetch();
        return slides.isEmpty ? null : slides;
      } catch (_) {
        return null;
      }
    });

class OnboardingDoneNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_doneKey) ?? false;

  Future<void> complete() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_doneKey, true);
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingDoneNotifier, bool>(
  OnboardingDoneNotifier.new,
);
