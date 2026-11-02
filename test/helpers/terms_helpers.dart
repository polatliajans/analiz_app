import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kriptoanaliz/providers/terms_acceptance_provider.dart';

/// Pretends the current terms were accepted, so widget tests that pump the
/// app root never land on the acceptance gate.
class AcceptedTerms extends TermsAcceptedNotifier {
  @override
  bool build() => true;
}

/// Add to a `ProviderScope`'s overrides to skip the terms gate.
final Override termsAcceptedOverride = termsAcceptedProvider.overrideWith(
  AcceptedTerms.new,
);
