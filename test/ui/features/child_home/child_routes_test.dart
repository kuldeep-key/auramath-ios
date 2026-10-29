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
    if (saved.isNotEmpty) {
      await tester.runAsync(() => deps.sessions.record('s1', 0, saved));
    }
    await tester.pumpWidget(const SizedBox()); // a fresh app, not a rebuild
    await tester.pumpWidget(AuraApp(deps: deps, initialLocation: at));
    await settle(tester);
    return deps;
  }

  testWidgets('Home shows the child named by the server', (tester) async {
    await boot(tester, Paths.home);
    expect(find.text('Mira'), findsOneWidget);
  });

  testWidgets('My badges lists what this phone earned', (tester) async {
    await boot(
      tester,
      Paths.badges,
      saved: const [
        SpecEvent('badge_awarded', {'badge_id': 'tree'}),
      ],
    );
    expect(find.text('Tree Detective'), findsOneWidget);
    expect(find.text('Brave Asker'), findsOneWidget); // next to earn
  });

  testWidgets('an unknown badge or next case goes somewhere sensible', (
    tester,
  ) async {
    await boot(tester, Paths.badge('nope'));
    expect(find.text('NEXT TO EARN'), findsOneWidget);

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
