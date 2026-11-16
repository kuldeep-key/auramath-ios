import 'package:auramath/app.dart';
import 'package:auramath/deps.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';

/// The routes wired to the real router and this phone's saved events.
void main() {
  Future<Deps> boot(
    WidgetTester tester,
    String at, {
    Map<String, String> stored = pairedChildPhone,
    List<SpecEvent> saved = const [],
    void Function(FakeServer server)? serve,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (deps, server) =
        await tester.runAsync(() => testDeps(stored: stored)) ??
        (throw StateError('no deps'));
    server.on('GET /api/children', {
      'children': [
        {'id': 'child-1', 'displayName': 'Mira'},
      ],
    });
    serve?.call(server);
    if (saved.isNotEmpty) {
      await tester.runAsync(() => deps.sessions.record('s1', 0, saved));
    }
    await tester.pumpWidget(const SizedBox()); // a fresh app, not a rebuild
    await tester.pumpWidget(AuraApp(deps: deps, initialLocation: at));
    await settle(tester);
    return deps;
  }

  testWidgets('My badges adds the level badges the server served (REW-06)', (
    tester,
  ) async {
    await boot(
      tester,
      Paths.badges,
      serve: (server) => server.on('GET /api/children/child-1/rewards', {
        'levelBadges': [
          {
            'badgeId': 'level.cmp.comparison.l4',
            'kind': 'skill_mastered',
            'name': 'Taller and shorter, up to 1000',
            'questionType': 'cmp.comparison',
            'level': 'L4',
            'sessionId': 's1',
            'draftName': true,
          },
          // another kind is not a level badge
          {'badgeId': 'tree', 'kind': 'session', 'name': 'Tree'},
        ],
      }),
    );
    expect(find.text('Taller and shorter, up to 1000'), findsOneWidget);
    await tester.tap(find.text('Taller and shorter, up to 1000'));
    await settle(tester);
    expect(find.text('Taller and shorter, up to 1000'), findsWidgets);
    expect(find.text('My badges'), findsNothing); // its own screen
  });

  testWidgets('no level badges served: only what this phone earned', (
    tester,
  ) async {
    await boot(tester, Paths.badges);
    expect(find.text('Your badges will live here.'), findsOneWidget);
  });

  testWidgets('Home shows the child named by the server', (tester) async {
    await boot(tester, Paths.home);
    expect(find.text('Mira'), findsOneWidget);
  });

  testWidgets('ACC-12: the child picks one of eight looks with PUT look; '
      'Home shows it', (tester) async {
    late FakeServer server;
    await boot(
      tester,
      Paths.home,
      serve: (s) =>
          (server = s).routes['PUT /api/children/child-1/look'] = (body) => (
            200,
            {
              'childId': 'child-1',
              'world': 'detective',
              'avatarId': body['avatarId'],
              'tutorId': 'teacher_1',
              'voiceId': 'voice_a',
              'needsFirstRun': <String>[],
            },
          ),
    );
    await tester.tap(find.byKey(const Key('pickAvatar')));
    await settle(tester);
    expect(find.text('Who do you want to be?'), findsWidgets);
    for (var i = 1; i <= 8; i++) {
      expect(find.bySemanticsLabel('Look $i'), findsOneWidget);
    }
    // never a gender
    expect(
      find.textContaining(RegExp('boy|girl', caseSensitive: false)),
      findsNothing,
    );
    await tester.tap(find.bySemanticsLabel('Look 3'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('choose')));
    await settle(tester);
    final put = server.calls.lastWhere((c) => c.$1.startsWith('PUT'));
    expect(put.$1, 'PUT /api/children/child-1/look');
    expect(put.$2, {'avatarId': 'look_03'});
    expect(find.byIcon(Icons.key_rounded), findsWidgets, reason: 'on Home');
    expect(find.text('Mira'), findsOneWidget);
  });

  testWidgets('ACC-12: a server before looks: the avatar route, with the '
      'look id (contract 4)', (tester) async {
    late FakeServer server;
    await boot(
      tester,
      Paths.avatar,
      serve: (s) => (server = s).on('PUT /api/children/child-1/avatar', {
        'id': 'child-1',
      }),
    );
    await tester.tap(find.byKey(const Key('surprise')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('choose')));
    await settle(tester);
    final put = server.calls.lastWhere((c) => c.$1.startsWith('PUT'));
    expect(put.$1, 'PUT /api/children/child-1/avatar');
    expect('${put.$2['avatar']}', matches(RegExp(r'^look_0[1-8]$')));
  });

  testWidgets('ACC-12: a phone the server won\'t let set it (403) asks for '
      'a grown-up', (tester) async {
    await boot(
      tester,
      Paths.avatar,
      serve: (s) => s.on('PUT /api/children/child-1/look', {
        'error': 'another child from this phone',
      }, status: 403),
    );
    await tester.tap(find.bySemanticsLabel('Look 4'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('choose')));
    await settle(tester);
    expect(find.textContaining('Ask a grown-up'), findsOneWidget);
    expect(find.textContaining("didn't save"), findsNothing);
  });

  testWidgets("ACC-12: a save that fails says so and stays", (tester) async {
    await boot(
      tester,
      Paths.avatar,
      serve: (s) => s.on('PUT /api/children/child-1/look', {
        'error': 'down',
      }, status: 503),
    );
    await tester.tap(find.bySemanticsLabel('Look 4'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('choose')));
    await settle(tester);
    expect(find.textContaining("didn't save"), findsOneWidget);
  });

  testWidgets('REW-12: the cabinet is the server\'s, earned badges only; '
      'another child\'s case on this phone is not this child\'s', (
    tester,
  ) async {
    await boot(
      tester,
      Paths.badges,
      // s1 is the fake server's other child's session
      saved: const [
        SpecEvent('problem_completed', {
          'problem_id': 'lemon',
          'outcome': 'solved_alone',
        }),
      ],
      serve: (server) => server.on('GET /api/children/child-1/rewards', {
        'world': 'detective',
        'cabinet': [
          {'badgeId': 'first_case', 'kind': 'first_case', 'name': 'First Case'},
          {
            'badgeId': 'stop.orchard.l1',
            'kind': 'skill_mastered',
            'name': 'Seedling Path',
          },
        ],
      }),
    );
    expect(find.text('First Case'), findsOneWidget);
    expect(find.text('Seedling Path'), findsOneWidget);
    // never an outline, one still to earn, or a count
    expect(find.text('Tree Detective'), findsNothing);
    expect(find.text('Brave Asker'), findsNothing);
    expect(find.textContaining(' of '), findsNothing);
  });

  testWidgets('an unknown badge or next case goes somewhere sensible', (
    tester,
  ) async {
    await boot(tester, Paths.badge('nope'));
    expect(find.text('Your badges will live here.'), findsOneWidget);

    await boot(tester, Paths.afterCaseNext('nope'));
    expect(find.text('Ready for a new case?'), findsOneWidget);
  });

  testWidgets('after a case with nothing saved, X1 shows the next case', (
    tester,
  ) async {
    await boot(tester, Paths.afterCaseNext('mango'));
    expect(find.text('Tree Word Problem'), findsOneWidget);
    expect(find.text('My sash'), findsNothing);
  });

  testWidgets('the trail starts at the first case stop', (tester) async {
    await boot(tester, Paths.trail);
    expect(find.text('You are here'), findsOneWidget);
    expect(find.text('Tree cases'), findsOneWidget);
  });
}

/// Lets the outbox reads and the fake server answer, then settles.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}
