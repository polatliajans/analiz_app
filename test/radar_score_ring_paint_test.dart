import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/widgets/radar/radar_widgets.dart';

void main() {
  testWidgets('score ring arc is opaque/bright while the track stays dim', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black,
              child: RadarScoreRing(
                score: 78,
                size: 200,
                brightness: Brightness.dark,
                trackColor: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final data = await tester.runAsync(() async {
      final img = await boundary.toImage();
      final bytes = await img.toByteData();
      return (img.width, bytes!);
    });
    final w = data!.$1;
    final bytes = data.$2;
    double luma(int x, int y) {
      final i = (y * w + x) * 4;
      return (bytes.getUint8(i) +
              bytes.getUint8(i + 1) +
              bytes.getUint8(i + 2)) /
          3 /
          255;
    }

    // Arc: 3 o'clock is within 78% sweep. Track: ~330deg clockwise from top.
    final arc = luma(189, 100);
    final track = luma(56, 23);
    expect(arc, greaterThan(0.45), reason: 'arc must be bright');
    expect(track, lessThan(0.2), reason: 'track must stay dim');
    expect(arc, greaterThan(track * 3));
  });
}
