import 'package:auramath/app.dart';
import 'package:auramath/deps.dart';
import 'package:auramath/routing/paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../lesson/fakes.dart';

/// journey_avatar_tutor.feature: first run (JRN-01), Home and the Me
/// screen (JRN-02), the tutor and its voice (TTR-01, TTR-03, TTR-06).
void main() {
  Future<(Deps, FakeServer)> boot(
    WidgetTester tester,
    String at, {
    List<String> needs = const [],
    Map<String, Object?> flags = allScreensOn,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (deps, server) =
        await tester.runAsync(
          () => testDeps(stored: pairedChildPhone, flags: flags),
        ) ??
        (throw StateError('no deps'));
    server.on('GET /api/children', {
      'children': [
        {'id': 'child-1', 'displayName': 'Aarav'},
      ],
    });
    var left = [...needs];
    Map<String, Object?> look([Map<String, Object?> body = const {}]) => {
      'childId': 'child-1',
      'world': 'detective',
      'avatarId': body['avatarId'] ?? 'look_05',
      'tutorId': body['tutorId'] ?? 'robot',
      'voiceId': body['voiceId'] ?? 'voice_c',
      'needsFirstRun': left,
    };
    // the server keeps every change
    var kept = <String, Object?>{};
    server.routes['GET /api/children/child-1/look'] = (_) => (200, look(kept));
    server.routes['PUT /api/children/child-1/look'] = (b) {
      kept = {...kept, ...b};
      return (200, look(kept));
    };
    server.routes['POST /api/children/child-1/first-run'] = (b) {
      left = [
        for (final s in left)
          if (s != b['step']) s,
      ];
      return (200, look());
    };
    server.on('POST /api/visits/${deps.visits.visitId}/events', {});
    await tester.pumpWidget(AuraApp(deps: deps, initialLocation: at));
    await settle(tester);
    return (deps, server);
  }

  testWidgets('JRN-01: first run in order, look, tutor, Meet, then Home; '
      'the world step skipped while one world is enabled', (tester) async {
    final (deps, server) = await boot(
      tester,
      Paths.home,
      needs: const ['world', 'look', 'tutor', 'meet'],
    );
    expect(find.text('Who do you want to be?'), findsWidgets);
    expect(server.calls.where((c) => c.$1.endsWith('/first-run')).first.$2, {
      'step': 'world',
    });
    await tester.tap(find.bySemanticsLabel('Look 2'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('choose')));
    await settle(tester);
    expect(find.text('Who will teach you?'), findsWidgets);
    expect(find.bySemanticsLabel('Tutor 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Tutor 3'), findsOneWidget);
    expect(find.byKey(const Key('surprise')), findsOneWidget);
    // each tutor says hello in its own voice
    await tester.tap(find.bySemanticsLabel('Tutor 2'));
    await settle(tester);
    final voice = deps.voice as FakeVoice;
    expect(voice.saidIn.last, startsWith('voice_b: Hi! I'));
    await tester.tap(find.byKey(const Key('choose')));
    await settle(tester);
    // Meet: the tutor's introduction, filled from the world, no name
    expect(find.textContaining('you are the lead detective'), findsOneWidget);
    expect(find.textContaining('{'), findsNothing);
    expect(find.textContaining('Aarav'), findsNothing);
    await tester.tap(find.text("Let's start"));
    await settle(tester);
    expect(find.text('Keep going'), findsOneWidget);
    expect(
      [
        for (final c in server.calls)
          if (c.$1.endsWith('/first-run')) c.$2['step'],
      ],
      ['world', 'look', 'tutor', 'meet'],
    );
    // no session yet: first run is not a session (SES-05)
    expect(server.calls.where((c) => c.$1.contains('/sessions')), isEmpty);
  });

  testWidgets('JRN-01: it picks up at the first unanswered step', (
    tester,
  ) async {
    await boot(tester, Paths.home, needs: const ['tutor', 'meet']);
    expect(find.text('Who will teach you?'), findsWidgets);
  });

  testWidgets('JRN-02: Home has the look, the name, the lock, the tutor with '
      'its greeting (no name), Keep going and the tiles; the Me screen has '
      'no world and no passcode', (tester) async {
    final (deps, _) = await boot(tester, Paths.home);
    expect(find.text('Aarav'), findsOneWidget);
    expect(find.byTooltip('For grown-ups'), findsOneWidget);
    expect(find.byKey(const Key('tutor')), findsOneWidget);
    expect(find.text('Your case is waiting.'), findsOneWidget);
    final voice = deps.voice as FakeVoice;
    expect(voice.said, contains('Your case is waiting.'));
    expect(voice.said.where((s) => s.contains('Aarav')), isEmpty);
    expect(find.text('Keep going'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pickAvatar')));
    await settle(tester);
    expect(find.byKey(const Key('myLook')), findsOneWidget);
    expect(find.byKey(const Key('myTutor')), findsOneWidget);
    expect(find.byKey(const Key('myVoice')), findsOneWidget);
    expect(find.byKey(const Key('myWorld')), findsNothing);
    expect(find.textContaining('passcode'), findsNothing);
  });

  testWidgets('TTR-06: switching the voice: each heard first, then saved', (
    tester,
  ) async {
    final (deps, server) = await boot(tester, Paths.pickVoice);
    await tester.tap(find.bySemanticsLabel('Voice 1'));
    await settle(tester);
    final voice = deps.voice as FakeVoice;
    expect(voice.saidIn.last, startsWith('voice_a: '));
    await tester.tap(find.byKey(const Key('choose')));
    await settle(tester);
    final put = server.calls.lastWhere((c) => c.$1.startsWith('PUT'));
    expect(put.$2, {'voiceId': 'voice_a'});
    expect(deps.looks.cached('child-1')?.voiceId, 'voice_a');
  });

  testWidgets('JRN-07: the next session records the look the server keeps', (
    tester,
  ) async {
    final (deps, _) = await boot(tester, Paths.home);
    expect(deps.sessions.lookFor('child-1'), (
      avatarId: 'look_05',
      tutorId: 'robot',
      voiceId: 'voice_c',
      world: 'detective',
    ));
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}
