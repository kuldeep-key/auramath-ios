import 'package:auramath/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui/features/lesson/fakes.dart';

void main() {
  testWidgets('app boots on Home and Keep going opens the lemon question', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (sessions, _, _) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
    final voice = FakeVoice();

    await tester.pumpWidget(
      AuraApp(sessions: sessions, pack: samplePack(), voice: voice),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ready for a new case?'), findsOneWidget);

    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text("Got it, let's draw"), findsOneWidget);
    expect(voice.said.last, startsWith('The lemon tree is 186 centimetres'));

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Ready for a new case?'), findsOneWidget);
  });

  testWidgets('after something easier, a clean solve opens lemon again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (sessions, _, _) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
    await tester.pumpWidget(
      AuraApp(sessions: sessions, pack: samplePack(), voice: FakeVoice()),
    );
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

    expect(find.textContaining('186 cm'), findsOneWidget);
    expect(find.text("Got it, let's draw"), findsOneWidget);
    await tap(find.byIcon(Icons.home_rounded));
  });
}
