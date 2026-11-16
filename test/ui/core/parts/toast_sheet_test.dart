import 'package:auramath/ui/core/motion/motion.dart';
import 'package:auramath/ui/core/parts/aura_sheet.dart';
import 'package:auramath/ui/core/parts/aura_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The prototype's toast and sheet timings (toastIn, sheetUp, sheetDown,
/// fade, fadeOut), frame by frame.
void main() {
  setUp(() => AuraMotion.still = false);
  tearDown(() => AuraMotion.still = true);

  Future<BuildContext> app(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return ctx;
  }

  double lift(WidgetTester tester, Key card) => tester
      .widget<FractionalTranslation>(
        find
            .ancestor(
              of: find.byKey(card),
              matching: find.byType(FractionalTranslation),
            )
            .first,
      )
      .translation
      .dy;

  testWidgets('toast: drops in over 400 ms, stays to 2.6 s, gone by 2.9 s', (
    tester,
  ) async {
    final ctx = await app(tester);
    AuraToast.show(ctx, 'Saved');
    await tester.pump();
    const toast = Key('auraToast');
    expect(lift(tester, toast), closeTo(-1.4, 0.01)); // 140 % above
    await tester.pump(const Duration(milliseconds: 200));
    final half = lift(tester, toast);
    expect(half, greaterThan(-1.4));
    expect(half, lessThan(0.1)); // the sheet curve overshoots a little
    await tester.pump(const Duration(milliseconds: 200));
    expect(lift(tester, toast), closeTo(0, 0.01));
    await tester.pump(const Duration(milliseconds: 2150));
    expect(lift(tester, toast), closeTo(0, 0.01)); // 2.55 s: still there
    await tester.pump(const Duration(milliseconds: 200));
    // 2.75 s: half way out, linear, to 150 % above
    expect(lift(tester, toast), closeTo(-0.75, 0.05));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('Saved'), findsNothing);
  });

  test('toast lift by the clock', () {
    expect(AuraToast.liftAt(Duration.zero), closeTo(1.4, 1e-9));
    expect(AuraToast.liftAt(const Duration(milliseconds: 400)), 0);
    expect(AuraToast.liftAt(const Duration(milliseconds: 2600)), 0);
    expect(AuraToast.liftAt(const Duration(milliseconds: 2900)), 1.5);
  });

  testWidgets('a newer toast replaces the one showing', (tester) async {
    final ctx = await app(tester);
    AuraToast.show(ctx, 'Sent again');
    await tester.pump(const Duration(milliseconds: 500));
    AuraToast.show(ctx, 'Signed in');
    await tester.pump();
    expect(find.text('Sent again'), findsNothing);
    expect(find.text('Signed in'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('sheet: rises over 420 ms on a scrim that fades in over 250 '
      'ms; drops in 250 ms', (tester) async {
    final ctx = await app(tester);
    final done = showAuraSheet<int>(
      ctx,
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).pop(7),
        child: const Text('Pick'),
      ),
    );
    await tester.pump();
    const sheet = Key('auraSheet');
    expect(lift(tester, sheet), closeTo(1.1, 0.01)); // 110 % below
    double scrim() =>
        tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .map((b) => b.color)
            .firstWhere((c) => c.b > 0.4 && c.r < 0.1)
            .a;
    await tester.pump(const Duration(milliseconds: 250));
    expect(scrim(), closeTo(AuraSheetRoute.scrim.a, 0.01)); // fully in
    expect(lift(tester, sheet), greaterThan(-0.05));
    await tester.pump(const Duration(milliseconds: 170));
    expect(lift(tester, sheet), closeTo(0, 0.01));

    await tester.tap(find.text('Pick'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    // ease-in: half the time, well under half the way
    final down = lift(tester, sheet);
    expect(down, greaterThan(0.1));
    expect(down, lessThan(0.55));
    await tester.pump(const Duration(milliseconds: 130));
    expect(find.byKey(sheet), findsNothing);
    expect(await done, 7);
  });

  test('sheet positions by the clock', () {
    expect(AuraSheetRoute.dropAt(0, closing: false), closeTo(1.1, 1e-9));
    expect(AuraSheetRoute.dropAt(1, closing: false), closeTo(0, 1e-9));
    expect(AuraSheetRoute.dropAt(1, closing: true), closeTo(0, 1e-9));
    expect(AuraSheetRoute.dropAt(0, closing: true), closeTo(1.1, 1e-9));
    // the scrim is in once 250 of the 420 ms have gone
    expect(AuraSheetRoute.scrimAt(250 / 420, closing: false), 1);
  });

  testWidgets('a tap on the scrim closes the sheet', (tester) async {
    final ctx = await app(tester);
    showAuraSheet<void>(ctx, builder: (_) => const Text('Time each day'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Time each day'), findsNothing);
  });
}
