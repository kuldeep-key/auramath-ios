import 'package:auramath/app.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data/helpers.dart' show lessonEvents;
import 'helpers/app_harness.dart';
import 'ui/features/lesson/fakes.dart';

void main() {
  testWidgets('app boots on Home and Keep going opens the lemon question', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (deps, _) =
        await tester.runAsync(() => testDeps(stored: pairedChildPhone)) ??
        (throw StateError('no deps'));
    final voice = deps.voice as FakeVoice;

    await tester.pumpWidget(AuraApp(deps: deps));
    await tester.pumpAndSettle();
    expect(find.text('Ready for a new case?'), findsOneWidget);

    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text("Got it, let's draw"), findsOneWidget);
    expect(voice.said.last, startsWith('The lemon tree is 186 centimetres'));

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Take a break?'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Go home'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(find.text('Ready for a new case?'), findsOneWidget);
  });

  testWidgets('Keep going reopens an unfinished case where it was left', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (deps, _) =
        await tester.runAsync(() => testDeps(stored: pairedChildPhone)) ??
        (throw StateError('no deps'));
    final pack = deps.pack;
    final sessions = deps.sessions;
    await tester.runAsync(() async {
      await sessions.record(
        'old',
        0,
        lessonEvents(pack, pack.problems['lemon']!, const [
          Started(),
          BarADrawn(),
        ]),
      );
    });
    await tester.pumpWidget(AuraApp(deps: deps));
    await tester.pumpAndSettle();

    // the first Home with a case left open is WelcomeBack (651:133)
    expect(find.text('Your case is waiting.'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text("Let's see"));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Welcome back. Here is your drawing.'), findsOneWidget);
    expect(find.text('Shorter'), findsNothing); // still placing bar B
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
  });

  testWidgets('after something easier, a clean solve opens lemon again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (deps, _) =
        await tester.runAsync(() => testDeps(stored: pairedChildPhone)) ??
        (throw StateError('no deps'));
    await tester.pumpWidget(AuraApp(deps: deps));
    await tester.pumpAndSettle();

    Future<void> tap(Finder f) async {
      await tester.runAsync(() async {
        await tester.tap(f);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
    }

    await tap(find.text('Keep going'));
    await tap(find.text("Got it, let's draw"));
    await tap(find.text('Help me'));
    await tap(find.text('Something easier'));
    expect(find.textContaining('254 cm'), findsOneWidget);
    await tap(find.text("Got it, let's draw"));
    await tap(find.text('I know it'));
    for (final d in ['1', '2', '2']) {
      await tap(find.text(d).last);
    }
    await tap(find.byIcon(Icons.check_rounded));
    await tap(find.text('Next'));
    await tap(find.text('Add to my sash'));

    // a paired phone that is online: Y4, then X1 with the lemon case the
    // engine chose next
    expect(find.text('My sash'), findsOneWidget);
    await tap(find.text('Next case'));
    expect(find.text('Ready for a trickier one?'), findsOneWidget);
    await tap(find.text("Let's go"));
    expect(find.textContaining('186 cm'), findsOneWidget);
  });
}
