import 'dart:io';
import 'dart:ui' as ui;

import 'package:finansy/widgets/splash_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('заставка уходит и открывает приложение', (t) async {
    t.view.physicalSize = const Size(1320, 2868);
    t.view.devicePixelRatio = 3;
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: const MaterialApp(home: SplashOverlay(child: Scaffold(backgroundColor: Color(0xFF1A1E02), body: Center(child: Text('APP'))))),
    ));
    final out = Platform.environment['SHOTS'];
    for (final ms in [0, 500, 750, 950, 1150, 1400]) {
      if (ms > 0) await t.pump(Duration(milliseconds: ms == 500 ? 500 : ms - [0, 500, 750, 950, 1150, 1400][[0, 500, 750, 950, 1150, 1400].indexOf(ms) - 1]));
      await t.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await t.pump();
      if (out != null) {
        await t.runAsync(() async {
          final img = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 1);
          final d = await img.toByteData(format: ui.ImageByteFormat.png);
          File('$out/splash_$ms.png').writeAsBytesSync(d!.buffer.asUint8List());
        });
      }
    }
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(Image), findsNothing);
    expect(find.text('APP'), findsOneWidget);
  });
}
