import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/core/motion/screen_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The prototype's shared keyframes, frame by frame (motion runs here:
/// [AuraMotion.still] is off in these tests).
void main() {
  setUp(() => AuraMotion.still = false);
  tearDown(() => AuraMotion.still = true);

  Widget box(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );

  Matrix4 transformOf(WidgetTester t) =>
      t.widget<Transform>(find.byType(Transform).first).transform;

  test('cssFrames eases each segment, as CSS does', () {
    const f = [(0.0, 0.0), (0.5, 10.0), (1.0, 0.0)];
    expect(cssFrames(0.5, f, Curves.easeInOut), 10);
    expect(cssFrames(0.25, f, Curves.easeInOut), closeTo(5, 1e-9));
    // the curve is applied inside the first half, not across the run
    expect(
      cssFrames(0.1, f, Curves.easeInOut),
      closeTo(10 * Curves.easeInOut.transform(0.2), 1e-9),
    );
  });

  testWidgets('wobble: -7 px at 20 %, +7 px at 40 %, rest at 400 ms', (
    t,
  ) async {
    await t.pumpWidget(box(const Wobbly(count: 1, child: SizedBox(width: 9))));
    await t.pump(const Duration(milliseconds: 80));
    expect(transformOf(t).getTranslation().x, closeTo(-7, 0.3));
    await t.pump(const Duration(milliseconds: 80));
    expect(transformOf(t).getTranslation().x, closeTo(7, 0.3));
    await t.pump(const Duration(milliseconds: 240));
    expect(transformOf(t).getTranslation().x, closeTo(0, 0.01));
  });

  testWidgets('shake: -8 px at 120 ms, twice in 1.2 s', (t) async {
    await t.pumpWidget(box(const Shake(count: 1, child: SizedBox(width: 9))));
    await t.pump(const Duration(milliseconds: 120));
    expect(transformOf(t).getTranslation().x, closeTo(-8, 0.3));
    await t.pump(const Duration(milliseconds: 600));
    expect(transformOf(t).getTranslation().x, closeTo(-8, 0.3));
    await t.pump(const Duration(milliseconds: 480));
    expect(transformOf(t).getTranslation().x, closeTo(0, 0.01));
  });

  testWidgets('sheetUp: below at the start, overshoots, rests at 420 ms', (
    t,
  ) async {
    await t.pumpWidget(box(const SheetUp(child: SizedBox(height: 100))));
    double y() => t
        .widget<FractionalTranslation>(find.byType(FractionalTranslation))
        .translation
        .dy;
    expect(y(), closeTo(1.1, 0.01));
    await t.pump(const Duration(milliseconds: 300));
    expect(y(), lessThan(0)); // the sheet curve's small overshoot
    await t.pump(const Duration(milliseconds: 120));
    expect(y(), closeTo(0, 0.001));
  });

  testWidgets('twinkle: 0.7 at rest, 0.15 at 1.2 s', (t) async {
    await t.pumpWidget(box(const Twinkle(child: Text('✦'))));
    double o() => t.widget<Opacity>(find.byType(Opacity)).opacity;
    expect(o(), closeTo(0.7, 0.01));
    await t.pump(const Duration(milliseconds: 1200));
    expect(o(), closeTo(0.15, 0.01));
  });

  testWidgets('burst: 1.15 and +6° at 60 %, rest at 900 ms', (t) async {
    await t.pumpWidget(box(const Burst(child: SizedBox(width: 9))));
    await t.pump(const Duration(milliseconds: 540));
    final scale = t.widgetList<Transform>(find.byType(Transform)).last;
    expect(scale.transform.getMaxScaleOnAxis(), closeTo(1.15, 0.01));
    await t.pump(const Duration(milliseconds: 360));
    expect(
      t
          .widgetList<Transform>(find.byType(Transform))
          .last
          .transform
          .getMaxScaleOnAxis(),
      closeTo(1, 0.001),
    );
  });

  testWidgets('reduced motion: everything at rest', (t) async {
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: box(const SheetUp(child: SizedBox(height: 100))),
      ),
    );
    expect(
      t
          .widget<FractionalTranslation>(find.byType(FractionalTranslation))
          .translation
          .dy,
      0,
    );
  });

  testWidgets('a pushed screen: 420 ms on the screen curve, the one below '
      'slides 28 % and dims to 0.6', (t) async {
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        theme: ThemeData(pageTransitionsTheme: auraPageTransitions),
        home: const Scaffold(body: Text('below')),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('top')),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 210));
    final w = t.view.physicalSize.width / t.view.devicePixelRatio;
    final topX = t.getTopLeft(find.text('top')).dx;
    // halfway in time is far along the curve
    final e = AuraCurves.screen.transform(0.5);
    expect(topX, closeTo(w * (1 - e), 2));
    final belowX = t.getTopLeft(find.text('below')).dx;
    expect(belowX, closeTo(-0.28 * w * e, 2));
    await t.pump(const Duration(milliseconds: 210));
    expect(t.getTopLeft(find.text('top')).dx, closeTo(0, 0.5));
    await t.pumpAndSettle();
    // and back: the one below returns, the top one leaves to the right
    nav.currentState!.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 210));
    expect(t.getTopLeft(find.text('top')).dx, closeTo(w * e, 2));
    await t.pumpAndSettle();
    expect(find.text('top'), findsNothing);
  });
}
