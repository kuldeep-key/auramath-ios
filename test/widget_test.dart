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
}
