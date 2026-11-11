import 'package:auramath/l10n/app_localizations.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/core/parts/speak_button.dart';
import 'package:auramath/ui/features/child_home/views/home_screen.dart';
import 'package:auramath/ui/features/child_home/views/voice_screens.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath/ui/features/lesson/views/lesson_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../data/helpers.dart' show expectContract;
import '../../../helpers/shots.dart';
import 'fakes.dart';

/// NFR-06: a speaker on every child screen, and the Sound screen (journey
/// 20) when read-aloud is off.
void main() {
  testWidgets('Home has a speaker that reads its line', (tester) async {
    spokenInShots.clear();
    await tester.pumpWidget(
      shotApp(
        const HomeScreen(
          name: 'Mia',
          grownUps: '/',
          trail: false,
          badges: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('speak')));
    expect(spokenInShots, ['Ready for a new case?']);
    expect(tester.getSize(find.byKey(const Key('speak'))).height, 56);
  });

  testWidgets('no ReadAloud above: no speaker', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpeakButton(text: 'Hi')),
      ),
    );
    expect(find.byKey(const Key('speak')), findsNothing);
  });

  testWidgets('read-aloud off: the lesson asks once a sitting; Sound on '
      'reads the question and logs prompt_answered', (tester) async {
    final (sessions, db, api) =
        await tester.runAsync(memorySessions) ?? (throw StateError('no db'));
    addTearDown(() => tester.runAsync(db.close));
    final voice = FakeVoice();
    final sitting = Sitting(capMs: 30 * 60 * 1000);
    final vm =
        LessonViewModel(
            pack: samplePack(),
            problemId: 'lemon',
            sessionId: 's1',
            sessions: sessions,
            voice: voice,
            openSession: sessions.open,
            sitting: sitting,
            tickEvery: null,
          )
          ..readAloud = false
          ..readAloudFlag = true;
    addTearDown(vm.dispose);
    await tester.runAsync(vm.start);
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) =>
                  LessonFlow(vm: vm, onHome: () {}, onFinished: (_) {}),
            ),
            GoRoute(path: Paths.sound, builder: (_, _) => const SoundScreen()),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SoundScreen), findsOneWidget);
    expect(voice.said, isEmpty);
    await tester.runAsync(() async {
      await tester.tap(find.text('Sound is on now'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(find.byType(SoundScreen), findsNothing);
    expect(vm.readAloud, isTrue);
    expect(voice.said.single, startsWith('The lemon tree is 186'));
    final answered = api.received.lastWhere((e) => e.name == 'prompt_answered');
    expect(answered.payload, {'prompt': 'sound_on', 'choice': 'sound_on'});
    expect(sitting.soundAsked, isTrue);
    expectContract(api.received);
  });
}
