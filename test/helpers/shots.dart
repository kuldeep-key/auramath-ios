import 'dart:io';
import 'dart:ui' as ui;

import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The sizes every screen must fit (logical points). The first is the
/// Figma frame; SE is the smallest iPhone we support; iPad checks the
/// layout stays a centred column.
const shotSizes = {
  'iphone15': Size(390, 844),
  'iphoneSE': Size(375, 667),
  'proMax': Size(430, 932),
  'ipad': Size(820, 1180),
};

bool _fontsLoaded = false;

/// Real Nunito and Material icons, so a shot looks like the phone, not
/// boxes.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Variable.ttf'));
  await nunito.load();
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

/// Wraps [screen] the way the app does (theme, strings, text clamp), at
/// `/` of a router so it can navigate. Every other path shows its own
/// address, so a test can check where a tap went:
/// `expect(find.text('went to /setup/age'), findsOneWidget)`.
Widget shotApp(Widget screen) => MaterialApp.router(
  theme: buildAuraTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
  routerConfig: GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => screen)],
    errorBuilder: (_, state) => Scaffold(body: Text('went to ${state.uri}')),
  ),
);

/// Renders [screen] at every size in [shotSizes] and saves
/// `build/shots/<name>@<size>.png`. Fails if anything overflows at any
/// size (an overflow throws in the test), so this is also the
/// responsive check.
///
/// Wrap in nothing: it pumps [shotApp] itself unless [wrap] is false (for
/// a screen that brings its own MaterialApp, such as the whole app).
Future<void> shotAllSizes(
  WidgetTester tester,
  String name,
  Widget screen, {
  bool wrap = true,
  Map<String, Size> sizes = shotSizes,
}) async {
  await tester.runAsync(loadAppFonts);
  for (final MapEntry(key: label, value: size) in sizes.entries) {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot'),
        child: wrap ? shotApp(screen) : screen,
      ),
    );
    await _precacheAssets(tester);
    await tester.pumpAndSettle();
    await _save(tester, '$name@$label');
  }
  tester.view.reset();
}

/// Asset images decode asynchronously; without this a shot shows empty
/// frames where portraits and pictures go.
Future<void> _precacheAssets(WidgetTester tester) async {
  final context = tester.element(find.byKey(const ValueKey('shot')));
  final files = Directory('assets/images').listSync().whereType<File>().where(
    (f) => RegExp(r'\.(png|jpe?g|webp)$').hasMatch(f.path),
  );
  await tester.runAsync(
    () => Future.wait([
      for (final f in files)
        precacheImage(
          AssetImage('assets/images/${f.uri.pathSegments.last}'),
          context,
        ),
    ]),
  );
}

Future<void> _save(WidgetTester tester, String file) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/shots/$file.png')..createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
