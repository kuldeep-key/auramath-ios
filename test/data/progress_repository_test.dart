import 'dart:io';

import 'package:auramath/data/models/lesson_event.dart';
import 'package:auramath/data/repositories/progress_repository.dart';
import 'package:auramath/deps.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

const _min = 60 * 1000;

var _n = 0;
LessonEvent _e(String s, String name, Map<String, Object?> p, [int at = 0]) =>
    LessonEvent(
      eventId: 'e${_n++}',
      sessionId: s,
      seq: _n,
      at: at,
      name: name,
      childRef: 'ch_test1234',
      deviceId: 'dv_test1234',
      appVersion: '0.1.0',
      payload: p,
    );

/// A session that showed [problem] and solved it at [at] for [badge].
List<LessonEvent> _solved(
  String s,
  String problem, {
  int at = 0,
  String badge = 'tree',
}) => [
  _e(s, 'problem_shown', {'problem_id': problem}, at),
  _e(s, 'problem_completed', {'problem_id': problem}, at),
  _e(s, 'badge_awarded', {'badge_id': badge}, at),
];

/// A session left before it was solved (something easier, gone home).
List<LessonEvent> _left(String s, String problem) => [
  _e(s, 'problem_shown', {'problem_id': problem}),
];

ProgressRepository _repo(Deps deps, List<LessonEvent> events) =>
    ProgressRepository(
      pack: deps.pack,
      events: () async => events,
      sessions: deps.sessions,
      family: deps.family,
      account: deps.account,
    );

void main() {
  late Deps deps;
  late FakeServer server;

  setUp(() async => (deps, server) = await testDeps(stored: pairedChildPhone));

  test('every trail stop and the template skill are in the skill map', () {
    final map = File('assets/spec/skill-map.yaml').readAsStringSync();
    for (final stop in TrailStop.values) {
      expect(map, contains('  - id: ${stop.skillId}\n'));
    }
    expect(
      File('assets/spec/comparison-two-step.yaml').readAsStringSync(),
      contains('\nskill: ${TrailStop.trees.skillId}\n'),
    );
  });

  test('badges: each earned once, first earned first', () async {
    final repo = _repo(deps, [
      ..._solved('s1', 'lemon', badge: 'asker'),
      ..._solved('s2', 'mango'),
      ..._solved('s3', 'lemon', badge: 'asker'),
    ]);
    expect(await repo.earnedBadges(), ['asker', 'tree']);
    expect(await _repo(deps, []).earnedBadges(), isEmpty);
  });

  test('trail: the furthest stop solved; trees before anything', () async {
    expect(await _repo(deps, []).trail(), (
      here: TrailStop.trees,
      atTop: false,
    ));
    // "shorter" (L5) is further on; going back to L4 doesn't move back
    final repo = _repo(deps, [
      ..._solved('s1', 'lemon'),
      ..._solved('s2', 'shorter'),
      ..._solved('s3', 'mango'),
    ]);
    expect((await repo.trail()).here, TrailStop.trickyWords);
  });

  group('after a case', () {
    test('Y4 only when the family can see it', () async {
      final repo = _repo(deps, _solved('s1', 'lemon'));
      expect(
        (await repo.afterCase('mango', familyHears: true)).sentBadge,
        'tree',
      );
      expect(
        (await repo.afterCase('mango', familyHears: false)).sentBadge,
        isNull,
      );
    });

    test('Streak on the third case in a row, and only then', () async {
      Future<bool> streak(List<LessonEvent> events) async => (await _repo(
        deps,
        events,
      ).afterCase('mango', familyHears: false)).streak;
      final two = [
        ..._solved('s1', 'lemon', at: 0),
        ..._solved('s2', 'mango', at: 5 * _min),
      ];
      expect(await streak(two), isFalse);
      final three = [...two, ..._solved('s3', 'lemon', at: 10 * _min)];
      expect(await streak(three), isTrue);
      expect(
        await streak([...three, ..._solved('s4', 'mango', at: 15 * _min)]),
        isFalse,
      );
    });

    test('a case left, or a long gap, breaks the run', () async {
      Future<bool> streak(List<LessonEvent> events) async => (await _repo(
        deps,
        events,
      ).afterCase('mango', familyHears: false)).streak;
      expect(
        await streak([
          ..._solved('s1', 'lemon', at: 0),
          ..._left('s2', 'lemon'),
          ..._solved('s3', 'easier', at: 5 * _min),
          ..._solved('s4', 'mango', at: 10 * _min),
        ]),
        isFalse,
      );
      expect(
        await streak([
          ..._solved('s1', 'lemon', at: 0),
          ..._solved('s2', 'mango', at: 40 * _min),
          ..._solved('s3', 'lemon', at: 45 * _min),
        ]),
        isFalse,
      );
    });

    test('Up when the next case opens a stop not reached before', () async {
      final first = await _repo(
        deps,
        _solved('s1', 'lemon'),
      ).afterCase('shorter', familyHears: false);
      expect(first.opened, TrailStop.trickyWords);
      expect(first.solved?.id, 'lemon');
      expect(first.next.id, 'shorter');

      final again = await _repo(deps, [
        ..._solved('s1', 'shorter'),
        ..._solved('s2', 'easier'),
      ]).afterCase('shorter', familyHears: false);
      expect(again.opened, isNull);
    });
  });

  test('WelcomeBack once per launch, only with a case left open', () async {
    final repo = _repo(deps, []);
    final lemon = deps.pack.problems['lemon']!;
    await deps.sessions.record('s1', 0, [problemShown(lemon)]);
    expect(await repo.welcomeBackDue(), isTrue);
    expect(await repo.welcomeBackDue(), isFalse);

    final fresh = await testDeps(stored: pairedChildPhone);
    expect(await _repo(fresh.$1, []).welcomeBackDue(), isFalse);
  });

  test('the child name, kept for when the server can\'t be reached', () async {
    final repo = _repo(deps, []);
    server.on('GET /api/children', {
      'children': [
        {'id': 'child-0', 'displayName': 'Zed'},
        {'id': 'child-1', 'displayName': 'Mira'},
      ],
    });
    expect(await repo.childName(), 'Mira');
    server.on('GET /api/children', {'error': 'down'}, status: 503);
    expect(await repo.childName(), 'Mira');
    expect(repo.cachedName, 'Mira');
  });
}
