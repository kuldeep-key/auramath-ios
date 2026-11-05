import 'package:auramath/data/repositories/grown_up_repository.dart';
import 'package:auramath/data/services/key_store.dart';
import 'package:auramath/deps.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';

/// A signed-in grown-up's phone with a family on the fake server: two
/// children, one grown-up and an open invitation, one joined phone, and
/// one lesson this week for the first child.
class Gu {
  Gu._(this.deps, this.server, this.store)
    : repo = GrownUpRepository(deps.client, store);

  final Deps deps;
  final FakeServer server;
  final MemoryKeyStore store;
  final GrownUpRepository repo;

  static Future<Gu> make(WidgetTester tester) async {
    final (deps, server) =
        await tester.runAsync(() => testDeps(stored: parentPhone)) ??
        (throw StateError('no deps'));
    return Gu._(deps, server, MemoryKeyStore())..seed();
  }

  /// The calls made, as `METHOD /path`.
  List<String> get calls => [for (final (c, _) in server.calls) c];

  Map<String, Object?> bodyOf(String call) =>
      server.calls.lastWhere((c) => c.$1 == call).$2;

  void seed() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final started = now - 13 * 60000;
    server
      ..on('GET /api/children', {
        'children': [
          {
            'id': 'child-1',
            'displayName': 'Aarav',
            'profile': {'schoolYear': 'Year 2'},
          },
          {
            'id': 'child-2',
            'displayName': 'Maya',
            'profile': {'schoolYear': 'Year 1'},
          },
        ],
      })
      ..on('GET /api/parent/members', {
        'members': [
          {
            'id': null,
            'email': 'priya@gmail.com',
            'role': 'owner',
            'you': true,
            'revokedAt': null,
          },
        ],
      })
      ..on('GET /api/parent/invites', {
        'invites': [
          {
            'id': 'inv-1',
            'email': 'raj@example.com',
            'acceptedAt': null,
            'revokedAt': null,
            'expiresAt': now + 86400000,
          },
        ],
      })
      ..on('GET /api/devices', {
        'devices': [
          {'id': 'dev-1', 'label': "Aarav's iPhone", 'lastSeenAt': now},
        ],
      })
      ..on('GET /api/children/child-1/progress', {
        'sessions': [
          {
            'id': 's1',
            'kind': 'lesson',
            'seeded': false,
            'startedAt': started,
            'endedAt': started + 12 * 60000,
          },
          // a rehearsal never counts
          {
            'id': 's0',
            'kind': 'lesson',
            'seeded': true,
            'startedAt': started,
            'endedAt': started + 5 * 60000,
          },
        ],
      })
      ..on('GET /api/children/child-2/progress', {'sessions': <Object>[]})
      ..on('GET /api/sessions/s1/summary', {
        'lines': ['Practised comparing two bars.', 'Did the second one alone.'],
      })
      ..on('GET /api/children/child-1/plan', {
        'childId': 'child-1',
        'next': {'text': 'A comparison that says "shorter".'},
        'check': null,
        'away': null,
      })
      ..on('GET /api/children/child-2/plan', {
        'childId': 'child-2',
        'next': null,
        'check': null,
        'away': null,
      })
      ..on('GET /api/family/passcode', {
        'set': true,
        'length': 4,
        'lockedUntil': null,
      });
  }
}
