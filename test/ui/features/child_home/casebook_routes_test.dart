import 'package:auramath/app.dart';
import 'package:auramath/deps.dart';
import 'package:auramath/routing/paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/app_harness.dart';
import 'casebook_samples.dart';

/// REW-15 and REW-12 through the real router, against the fake server.
void main() {
  const casebookOn = {...allScreensOn, 'badge_cabinet': true, 'casebook': true};
  const casebookOff = {...allScreensOn, 'badge_cabinet': true};

  const cabinet = {
    'world': 'detective',
    'cabinet': [
      {
        'badgeId': 'first_case',
        'kind': 'first_case',
        'name': 'First Case',
        'problemId': 'lemon',
      },
    ],
  };

  Future<(Deps, FakeServer)> boot(
    WidgetTester tester,
    String at, {
    Map<String, Object?> flags = casebookOn,
    void Function(FakeServer server)? serve,
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
        {'id': 'child-1', 'displayName': 'Mira'},
      ],
    });
    serve?.call(server);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(AuraApp(deps: deps, initialLocation: at));
    await settle(tester);
    return (deps, server);
  }

  testWidgets('REW-15: Home has My casebook only while the switch is on', (
    tester,
  ) async {
    await boot(
      tester,
      Paths.home,
      serve: (server) => server.on('GET /api/children/child-1/casebook', {
        'world': 'detective',
        'days': <Object?>[],
      }),
    );
    expect(find.text('My casebook'), findsOneWidget);
    await tester.tap(find.text('My casebook'));
    await settle(tester);
    expect(find.text('Your solved cases will live here.'), findsOneWidget);

    await boot(tester, Paths.home, flags: casebookOff);
    expect(find.text('My casebook'), findsNothing);
    expect(find.text('My trail'), findsOneWidget);
    expect(find.text('Keep going'), findsOneWidget);
  });

  testWidgets('REW-15: the casebook is the server\'s: days, cases, stickers, '
      'and a case opens with its drawing', (tester) async {
    await boot(
      tester,
      Paths.casebook,
      serve: (server) {
        server.on('GET /api/children/child-1/casebook', sampleCasebook);
        server.on('GET /api/children/child-1/casebook/cases/lemon', sampleCase);
      },
    );
    expect(find.text('Mango Word Problem'), findsOneWidget);
    expect(find.text('Tree Word Problem'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('case-lemon')));
    await settle(tester);
    expect(find.text('YOUR DRAWING'), findsOneWidget);
    expect(find.text('186'), findsOneWidget);
    expect(find.text('Case cracked!'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await settle(tester);
    expect(find.text('Mango Word Problem'), findsOneWidget);
  });

  testWidgets('REW-15: offline, the casebook is ErrChild, and a retry that '
      'works shows it', (tester) async {
    var offline = true;
    final (_, server) = await boot(
      tester,
      Paths.casebook,
      serve: (server) =>
          server.routes['GET /api/children/child-1/casebook'] = (_) => offline
          ? throw http.ClientException('offline')
          : (200, sampleCasebook),
    );
    expect(find.text("That didn't work"), findsOneWidget);
    expect(find.byKey(const Key('errHome')), findsOneWidget);
    offline = false;
    await tester.tap(find.byKey(const Key('errRetry')));
    await settle(tester);
    expect(find.text('Mango Word Problem'), findsOneWidget);
    expect(server.calls.where((c) => c.$1.endsWith('/casebook')).length, 2);
  });

  testWidgets('REW-15: a refused case (500) is ErrChild too', (tester) async {
    await boot(
      tester,
      Paths.casebookCase('lemon'),
      serve: (server) => server.on(
        'GET /api/children/child-1/casebook/cases/lemon',
        {'error': 'boom'},
        status: 500,
      ),
    );
    expect(find.text("That didn't work"), findsOneWidget);
  });

  testWidgets('REW-15: with the switch off, the casebook goes home', (
    tester,
  ) async {
    await boot(tester, Paths.casebook, flags: casebookOff);
    expect(find.text('Keep going'), findsOneWidget);
    expect(find.text('My casebook'), findsNothing);
  });

  testWidgets('REW-12: a badge opens the case it came from', (tester) async {
    final (deps, server) = await boot(
      tester,
      Paths.badges,
      serve: (server) {
        server.on('GET /api/children/child-1/rewards', cabinet);
        server.on('GET /api/children/child-1/casebook/cases/lemon', sampleCase);
      },
    );
    await tester.tap(find.text('First Case'));
    await settle(tester);
    expect(find.text('YOUR DRAWING'), findsOneWidget);
    expect(find.text('Tree Word Problem'), findsOneWidget);
    expect(
      server.calls.map((c) => c.$1),
      contains('GET /api/children/child-1/casebook/cases/lemon'),
    );
  });

  testWidgets('REW-12: a badge whose case isn\'t there (404) shows alone', (
    tester,
  ) async {
    await boot(
      tester,
      Paths.badges,
      serve: (server) =>
          server.on('GET /api/children/child-1/rewards', cabinet),
    );
    await tester.tap(find.text('First Case'));
    await settle(tester);
    expect(find.text('YOUR DRAWING'), findsNothing);
    expect(find.text('Back to my badges'), findsOneWidget);
  });

  testWidgets('REW-12: with the casebook off, a badge shows alone, as before', (
    tester,
  ) async {
    final (_, server) = await boot(
      tester,
      Paths.badges,
      flags: casebookOff,
      serve: (server) =>
          server.on('GET /api/children/child-1/rewards', cabinet),
    );
    await tester.tap(find.text('First Case'));
    await settle(tester);
    expect(find.text('Back to my badges'), findsOneWidget);
    expect(server.calls.where((c) => c.$1.contains('casebook')), isEmpty);
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
