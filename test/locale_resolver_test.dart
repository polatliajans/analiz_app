import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/locale_resolver.dart';

void main() {
  test('a saved supported language wins over the device language', () {
    expect(
      resolveLocale(saved: 'es', deviceLocales: [const Locale('tr')]),
      const Locale('es'),
    );
  });

  test('uses the first supported device language', () {
    expect(
      resolveLocale(
        deviceLocales: [const Locale('de'), const Locale('tr', 'TR')],
      ),
      const Locale('tr'),
    );
  });

  test('matches regional variants by language code', () {
    expect(
      resolveLocale(deviceLocales: [const Locale('es', 'MX')]),
      const Locale('es'),
    );
  });

  test('falls back to English when nothing is supported', () {
    expect(
      resolveLocale(deviceLocales: [const Locale('de'), const Locale('fr')]),
      const Locale('en'),
    );
    expect(resolveLocale(deviceLocales: const []), const Locale('en'));
  });

  test('ignores a saved language that is no longer supported', () {
    expect(
      resolveLocale(saved: 'de', deviceLocales: [const Locale('es')]),
      const Locale('es'),
    );
  });
}
