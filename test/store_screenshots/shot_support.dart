// Support code for the Play Store screenshot capture (see
// store_screenshots_test.dart): real fonts, a 1080x2400 phone surface and
// PNG export of the rendered app.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/theme/app_theme.dart';

/// Capture is opt-in: `STORE_SHOTS=1 flutter test test/store_screenshots`.
final bool storeShotsEnabled = Platform.environment['STORE_SHOTS'] == '1';

/// Languages to render (comma separated), default all three.
List<String> storeShotLangs() =>
    (Platform.environment['STORE_SHOT_LANGS'] ?? 'en,tr,es').split(',');

/// Raw capture output; the composer (assets/brand/compose_screenshots.js)
/// turns these into the branded store images.
String storeShotRawDir() =>
    Platform.environment['STORE_SHOT_RAW'] ?? 'store_assets/screenshots/raw/render';

/// Directory holding Roboto + MaterialIcons (Flutter SDK material_fonts).
String _fontsDir() =>
    Platform.environment['STORE_SHOT_FONTS'] ??
    '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter'}'
        '/bin/cache/artifacts/material_fonts';

Future<void> loadStoreFonts() async {
  Future<ByteData> bytes(String f) async =>
      ByteData.view(Uint8List.fromList(File('${_fontsDir()}/$f').readAsBytesSync()).buffer);
  final roboto = FontLoader('Roboto');
  for (final f in [
    'roboto-light.ttf',
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-italic.ttf',
  ]) {
    roboto.addFont(bytes(f));
  }
  await roboto.load();
  // Text without an explicit family (k_chart axis labels) uses the test
  // harness font; point it at Roboto too so it is not rendered as boxes.
  final fallback = FontLoader('Ahem');
  for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf']) {
    fallback.addFont(bytes(f));
  }
  await fallback.load();
  final fallback2 = FontLoader('FlutterTest')..addFont(bytes('roboto-regular.ttf'));
  await fallback2.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(bytes('materialicons-regular.otf'));
  await icons.load();
}

/// Same insets as the phone captures (status bar 32dp, nav bar 44dp); the
/// composer crops them away.
const topInset = 32.0;
const bottomInset = 44.0;

void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

final shotKey = GlobalKey();

/// App shell for one screenshot: dark app theme, given language, phone insets.
Widget shotApp({
  required String lang,
  required Widget home,
  required ProviderContainer container,
  Brightness brightness = Brightness.dark,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: RepaintBoundary(
      key: shotKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(brightness),
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: topInset, bottom: bottomInset),
            viewPadding: const EdgeInsets.only(
              top: topInset,
              bottom: bottomInset,
            ),
          ),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
}

Future<void> savePng(WidgetTester tester, String lang, String name) async {
  await tester.runAsync(() async {
    final boundary =
        shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('${storeShotRawDir()}/$lang')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(
      data!.buffer.asUint8List(),
    );
  });
}
