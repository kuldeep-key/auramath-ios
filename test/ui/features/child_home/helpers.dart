import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/shots.dart';

/// Pumps [screen] at the Figma size, ready for taps.
Future<void> show(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = shotSizes['iphone15']! * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(shotApp(screen));
  await tester.pumpAndSettle();
}

Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// [shotAllSizes] with the portrait and trail art decoded first: an asset
/// image otherwise arrives after the shot is taken.
Future<void> shots(WidgetTester tester, String name, Widget screen) async {
  await tester.pumpWidget(const SizedBox());
  final context = tester.element(find.byType(SizedBox));
  await tester.runAsync(() async {
    for (final a in const [
      'assets/images/detective_boy.jpg',
      'assets/images/trail_ground.png',
      'assets/images/trail_over.png',
    ]) {
      await precacheImage(AssetImage(a), context);
    }
  });
  await shotAllSizes(tester, name, screen);
}
