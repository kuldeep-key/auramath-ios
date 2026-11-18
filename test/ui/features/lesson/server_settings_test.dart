import 'dart:io';

import 'package:auramath/app.dart';
import 'package:auramath/data/models/child_settings.dart';
import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/deps.dart';
import 'package:auramath/routing/paths.dart';
import 'package:auramath/ui/features/child_home/views/choose_today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';
import '../child_home/child_routes_test.dart' show settle;

/// PAR-05: the lesson runs with the child's settings as the server keeps
/// them, so a change on one family phone reaches the others.
void main() {
  const minute = 60 * 1000;

  Map<String, Object?> settingsJson({
    int? minutes,
    bool readAloud = true,
    bool readAloudIsDefault = false,
  }) => {
    'childId': 'child-1',
    'dailyLimitMinutes': minutes,
    'dailyLimitIsDefault': minutes == null,
    'readAloud': readAloud,
    'readAloudIsDefault': readAloudIsDefault,
  };

  Future<(Deps, FakeServer, FakeApi)> boot(
    WidgetTester tester, {
    void Function(FakeServer server)? serve,
    void Function(FakeApi api)? api,
    Map<String, String> stored = const {},
    String at = Paths.lessonNext,
    Map<String, Object?> flags = allScreensOn,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => AuraSound.soundOn.value = true);
    late FakeApi fake;
    final (deps, server) =
        await tester.runAsync(
          () => testDeps(
            stored: {...pairedChildPhone, ...stored},
            flags: flags,
            api: (a) {
              fake = a;
              api?.call(a);
            },
          ),
        ) ??
        (throw StateError('no deps'));
    server.on('GET /api/children', {
      'children': [
        {'id': 'child-1', 'displayName': 'Mira', 'age': 8},
      ],
    });
    serve?.call(server);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(AuraApp(deps: deps, initialLocation: at));
    await settle(tester);
    return (deps, server, fake);
  }

  testWidgets("the lesson's time each day is the server's", (tester) async {
    final (deps, _, _) = await boot(
      tester,
      serve: (s) =>
          s.on('GET /api/children/child-1/settings', settingsJson(minutes: 10)),
    );
    expect(deps.sitting.capMs, 10 * minute);
    // kept for when the server can't be reached
    expect(
      deps.store.read('childSettings.child-1'),
      completion(contains('10')),
    );
  });

  testWidgets('no limit on the server: the session cap', (tester) async {
    final (deps, _, _) = await boot(
      tester,
      serve: (s) => s.on('GET /api/children/child-1/settings', settingsJson()),
    );
    expect(deps.sitting.capMs, 30 * minute);
  });

  testWidgets('read-aloud turned off on another phone: the sounds follow', (
    tester,
  ) async {
    await boot(
      tester,
      serve: (s) => s.on(
        'GET /api/children/child-1/settings',
        settingsJson(minutes: 20, readAloud: false),
      ),
    );
    expect(AuraSound.soundOn.value, isFalse);
  });

  testWidgets('offline: the settings this phone kept', (tester) async {
    final (deps, _, _) = await boot(
      tester,
      stored: {
        'childSettings.child-1':
            '{"childId":"child-1","dailyLimitMinutes":15,'
            '"dailyLimitIsDefault":false,"readAloud":false,'
            '"readAloudIsDefault":false}',
      },
      serve: (s) =>
          s.routes['GET /api/children/child-1/settings'] = (_) =>
              throw const SocketException('offline'),
    );
    expect(deps.sitting.capMs, 15 * minute);
    expect(AuraSound.soundOn.value, isFalse);
  });

  group("SES-01: time's up, from the server's day", () {
    Map<String, Object?> day({required int leftMs, int capMs = 30 * minute}) =>
        {
          'limitMinutes': 20,
          'usedMs': 20 * minute - leftMs,
          'leftMs': leftMs,
          'capMs': leftMs < capMs ? leftMs : capMs,
          'timesUp': leftMs <= 0,
          'day': '2026-11-18',
          'timeZone': 'Australia/Sydney',
        };

    testWidgets("the lesson's cap is the server's capMs, not 30 minutes", (
      tester,
    ) async {
      final (deps, _, _) = await boot(
        tester,
        api: (a) => a.dailyTime = dailyTimeFromJson(day(leftMs: 7 * minute)),
      );
      expect(deps.sitting.capMs, deps.sitting.activeMs + 7 * minute);
      expect(find.text("That's today's time!"), findsNothing);
    });

    testWidgets('what is left of the day, read before the lesson opens', (
      tester,
    ) async {
      final (deps, _, _) = await boot(
        tester,
        serve: (s) => s.on('GET /api/children/child-1/settings', {
          ...settingsJson(minutes: 20),
          'today': day(leftMs: 4 * minute),
        }),
      );
      expect(deps.sitting.capMs, deps.sitting.activeMs + 4 * minute);
    });

    testWidgets("the server's 409: That's today's time!, and no lesson", (
      tester,
    ) async {
      final (_, _, api) = await boot(
        tester,
        api: (a) => a.timesUp = day(leftMs: 0),
      );
      expect(find.text("That's today's time!"), findsOneWidget);
      // nothing to finish, and never the internet screen
      expect(find.text('Finish this one'), findsNothing);
      expect(find.text('Check again'), findsNothing);
      // only the harness's own session: none opened for this lesson
      expect(api.sessions, hasLength(1));
      await tester.tap(find.text('Call it a day'));
      await settle(tester);
      expect(find.text("That's today's time!"), findsNothing);
    });

    testWidgets('time used up on another phone: no lesson is asked for', (
      tester,
    ) async {
      final (_, _, api) = await boot(
        tester,
        serve: (s) => s.on('GET /api/children/child-1/settings', {
          ...settingsJson(minutes: 20),
          'today': day(leftMs: 0),
        }),
      );
      expect(find.text("That's today's time!"), findsOneWidget);
      expect(api.sessions, hasLength(1));
    });

    testWidgets("Home's Keep going to Choose today, with no time left, says "
        "That's today's time!", (tester) async {
      await boot(
        tester,
        at: Paths.chooseToday,
        flags: {...allScreensOn, 'quick_sums': true},
        serve: (s) => s.on('GET /api/children/child-1/settings', {
          ...settingsJson(minutes: 20),
          'today': day(leftMs: 0),
        }),
      );
      expect(find.text("That's today's time!"), findsOneWidget);
    });

    testWidgets('time left: Choose today as before', (tester) async {
      await boot(
        tester,
        at: Paths.chooseToday,
        flags: {...allScreensOn, 'quick_sums': true},
        serve: (s) => s.on('GET /api/children/child-1/settings', {
          ...settingsJson(minutes: 20),
          'today': day(leftMs: 5 * minute),
        }),
      );
      expect(find.text("That's today's time!"), findsNothing);
      expect(find.byType(ChooseTodayScreen), findsOneWidget);
    });
  });
}
