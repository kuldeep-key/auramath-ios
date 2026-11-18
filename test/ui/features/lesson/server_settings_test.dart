import 'dart:io';

import 'package:auramath/app.dart';
import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath/data/services/sound_effects.dart';
import 'package:auramath/deps.dart';
import 'package:auramath/routing/paths.dart';
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
    await tester.pumpWidget(
      AuraApp(deps: deps, initialLocation: Paths.lessonNext),
    );
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
}
