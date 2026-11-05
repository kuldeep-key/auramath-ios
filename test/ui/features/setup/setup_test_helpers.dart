import 'package:auramath/deps.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/shots.dart';

/// Deps and a fake server, made outside the fake clock.
Future<(Deps, FakeServer)> setupDeps(
  WidgetTester tester, {
  Map<String, String> stored = const {},
}) async =>
    await tester.runAsync(() => testDeps(stored: stored)) ??
    (throw StateError('no deps'));

/// Shows [screen] at the Figma size, ready to tap.
Future<void> show(WidgetTester tester, Widget screen) async {
  await tester.runAsync(loadAppFonts);
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(shotApp(screen));
  await tester.pump();
}

/// Taps, lets the fake server answer, and settles.
Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

/// Lets pending server calls finish, then pumps a few frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Decodes [assets] now, so shots show the pictures (decoding needs the
/// real clock).
Future<void> precacheAssets(WidgetTester tester, List<String> assets) async {
  await tester.pumpWidget(const SizedBox());
  final context = tester.element(find.byType(SizedBox));
  await tester.runAsync(
    () => Future.wait([
      for (final a in assets) precacheImage(AssetImage(a), context),
    ]),
  );
}

/// Apple's and Google's buttons ask for the iPhone's system font, which a
/// test doesn't have: Nunito stands in so the shots are readable.
Future<void> loadSystemFontStandIn(WidgetTester tester) => tester.runAsync(
  () => (FontLoader(
    '.SF Pro Text',
  )..addFont(rootBundle.load('assets/fonts/Nunito-Variable.ttf'))).load(),
);

/// The routes [FakeServer] was called on, in order.
List<String> called(FakeServer server) => [
  for (final (r, _) in server.calls) r,
];
