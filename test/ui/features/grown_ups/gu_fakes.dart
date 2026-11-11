import 'dart:io';

import 'package:auramath/data/repositories/grown_up_repository.dart';
import 'package:auramath/data/services/key_store.dart';
import 'package:auramath/deps.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/app_harness.dart';

/// A signed-in grown-up's phone with a family on the fake server: two
/// children, one grown-up and an open invitation, one joined phone, and
/// one lesson this week for the first child.
class Gu {
  Gu._(this.deps, this.server, this.store, this.documents, this.cache)
    : repo = GrownUpRepository(
        deps.client,
        store,
        documents: () async => documents,
        cache: () async => cache,
      );

  /// The phone's documents and cache folders (DEV-06 sweeps them).
  final Directory documents;
  final Directory cache;

  final Deps deps;
  final FakeServer server;
  final MemoryKeyStore store;
  final GrownUpRepository repo;

  static Future<Gu> make(WidgetTester tester) async {
    final (deps, server) =
        await tester.runAsync(() => testDeps(stored: parentPhone)) ??
        (throw StateError('no deps'));
    final (documents, cache) = (await tester.runAsync(
      () async => (
        await Directory.systemTemp.createTemp('gu-docs'),
        await Directory.systemTemp.createTemp('gu-cache'),
      ),
    ))!;
    addTearDown(() async {
      for (final d in [documents, cache]) {
        if (d.existsSync()) d.deleteSync(recursive: true);
      }
    });
    return Gu._(deps, server, MemoryKeyStore(), documents, cache)..seed();
  }

  /// The calls made, as `METHOD /path`.
  List<String> get calls => [for (final (c, _) in server.calls) c];

  Map<String, Object?> bodyOf(String call) =>
      server.calls.lastWhere((c) => c.$1 == call).$2;

  void seed() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final started = now - 13 * 60000;
    server
      ..on('POST /api/auth/logout', null, status: 204)
      ..on('GET /api/family/settings/reports', {'frequency': 'each_session'})
      ..on('GET /api/children', {
        'children': [
          {'id': 'child-1', 'displayName': 'Aarav', 'schoolYear': 'year_2'},
          {'id': 'child-2', 'displayName': 'Maya', 'schoolYear': 'year_1'},
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
        'sentences': [
          {'part': 'practised', 'text': 'Practised comparing two bars.'},
          {'part': 'did_alone', 'text': 'Did the second one alone.'},
        ],
        'source': 'template',
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
      ..on('GET /api/parent/browsers', {
        'browsers': [
          {
            'id': 'cred-1',
            'label': 'iPhone',
            'memberId': null,
            'createdAt': now,
            'lastSeenAt': now,
            'you': true,
          },
          {
            'id': 'cred-2',
            'label': 'Chrome on Mac',
            'memberId': null,
            'createdAt': now,
            'lastSeenAt': now,
            'you': false,
          },
        ],
      })
      ..on('GET /api/parent/consents', {
        'consents': <Object>[],
        'consentAt': now,
        'consentWithdrawnAt': null,
        'consented': true,
        'problem': null,
      })
      ..on('GET /api/children/child-1/learning', {
        'childId': 'child-1',
        'questionTypes': {
          'cmp.comparison': {
            'level': 'L4',
            'cleanSolvesAtLevel': 1,
            'levelChanges': [
              {'from': 'L3', 'to': 'L4', 'reason': 'move_up'},
              {'from': 'L4', 'to': 'L3', 'reason': 'down_now'},
              {'from': 'L3', 'to': 'L4', 'reason': 'move_up'},
            ],
          },
        },
        'problems': 9,
        'mistakesSeen': {'E3': 2},
      })
      ..on('GET /api/children/child-2/learning', {
        'childId': 'child-2',
        'questionTypes': <String, Object>{},
        'problems': 0,
        'mistakesSeen': <String, Object>{},
      })
      ..on('GET /api/family/passcode', {
        'set': true,
        'length': 4,
        'lockedUntil': null,
      });
  }
}
