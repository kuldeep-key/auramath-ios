import 'package:auramath/data/models/journey_config.dart';
import 'package:auramath/data/repositories/look_repository.dart';
import 'package:auramath/data/repositories/session_repository.dart';
import 'package:auramath/data/repositories/visit_repository.dart';
import 'package:auramath/data/services/api_client.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import 'helpers.dart' show expectContract, WithSession;

/// D-59, D-60: the journey's settings from the bundled spec files, the
/// child's look as the server keeps it, and the events outside a lesson.
void main() {
  final config = bundledJourney();

  group('JourneyConfig (tutors, looks, catalogue, rules, journey)', () {
    test('three tutors enabled, teacher_1 by default, each its own voice', () {
      expect(config.enabledTutors, ['teacher_1', 'teacher_2', 'robot']);
      expect(config.pickable.map((t) => t.id), config.enabledTutors);
      expect(config.pickTutor, isTrue);
      expect(config.defaultTutor, 'teacher_1');
      expect(config.voices, ['voice_a', 'voice_b', 'voice_c']);
      expect(config.voiceFor('teacher_2'), 'voice_b');
      expect(config.voiceFor('robot', 'voice_a'), 'voice_a');
      // a voice that left the set: the tutor's own (voice_switched_off)
      expect(config.voiceFor('robot', 'voice_z'), 'voice_c');
      // names are Key's to give: none yet (open question)
      expect(config.tutors.every((t) => t.name == null), isTrue);
    });

    test('eight looks, Detective the only world, Coming soon tiles', () {
      expect(config.looks.map((l) => l.id), [
        for (var i = 1; i <= 8; i++) 'look_0$i',
      ]);
      expect(
        config.looks.first.costumes['detective'],
        'art.look.look_01.detective',
      );
      expect(config.enabledWorlds, ['detective']);
      expect(config.pickWorld, isFalse);
      expect(config.comingSoonWorlds, 2);
      expect(config.wordsOf('detective').role, 'lead detective');
      expect(config.wordsOf('detective').task, 'case');
      expect(config.wordsOf('nowhere').task, 'case');
    });

    test('first run order and the celebration lengths (REW-16)', () {
      expect(config.firstRun.first, 'whos_learning');
      expect(config.firstRun.last, 'home');
      expect(config.maxFor('case_solved'), const Duration(milliseconds: 1500));
      expect(config.maxFor('stop_badge'), const Duration(seconds: 3));
      expect(config.maxFor('land_badge'), const Duration(seconds: 8));
      expect(config.endOfCaseOrder, [
        'case_solved',
        'polish_cleared',
        'big_badge',
        'move_up_line',
      ]);
      expect(config.endOfSessionOrder, [
        'streak_moment',
        'session_badge',
        'secret_badge',
      ]);
    });

    test('only one tutor enabled: no picker (TTR-01)', () {
      const one = JourneyConfigTestOne();
      expect(one.config.pickTutor, isFalse);
    });
  });

  group('LookRepository (GET/PUT look, first run)', () {
    late FakeServer server;
    late LookRepository looks;
    setUp(() {
      server = FakeServer();
      looks = LookRepository(
        ApiClient(
          baseUrl: 'http://test',
          bearer: () => 'device-token',
          client: server.client,
        ),
        config,
      );
    });

    test('reads the look and the first-run steps still to do', () async {
      server.on('GET /api/children/c1/look', {
        'childId': 'c1',
        'world': 'detective',
        'avatarId': 'look_05',
        'tutorId': 'robot',
        'voiceId': 'voice_c',
        'needsFirstRun': ['tutor', 'meet'],
      });
      final look = await looks.read('c1');
      expect(look.avatarId, 'look_05');
      expect(look.needsFirstRun, ['tutor', 'meet']);
      expect(looks.sessionLook('c1'), (
        avatarId: 'look_05',
        tutorId: 'robot',
        voiceId: 'voice_c',
        world: 'detective',
      ));
    });

    test('a server before looks (404): the defaults, the old avatar as its '
        'look, and no first run', () async {
      final look = await looks.read('c1', avatar: 'map');
      expect(look.avatarId, 'look_04');
      expect(look.tutorId, 'teacher_1');
      expect(look.voiceId, 'voice_a');
      expect(look.needsFirstRun, isEmpty);
    });

    test('saving a tutor sends it and keeps what the server says', () async {
      server.routes['PUT /api/children/c1/look'] = (body) => (
        200,
        {
          'childId': 'c1',
          'world': 'detective',
          'avatarId': 'look_02',
          'tutorId': body['tutorId'] == 'surprise'
              ? 'teacher_2'
              : body['tutorId'],
          'voiceId': 'voice_b',
          'needsFirstRun': <String>[],
        },
      );
      final look = await looks.save('c1', tutorId: 'surprise');
      expect(server.calls.last.$2, {'tutorId': 'surprise'});
      expect(look.tutorId, 'teacher_2');
      expect(looks.cached('c1')?.voiceId, 'voice_b');
    });

    test('a first-run step done is told to the server and kept', () async {
      server.on('GET /api/children/c1/look', {
        'avatarId': 'look_01',
        'needsFirstRun': ['look', 'tutor', 'meet'],
      });
      server.on('POST /api/children/c1/first-run', null, status: 204);
      await looks.read('c1');
      await looks.stepDone('c1', 'look');
      expect(server.calls.last.$1, 'POST /api/children/c1/first-run');
      expect(server.calls.last.$2, {'step': 'look'});
      expect(looks.cached('c1')?.needsFirstRun, ['tutor', 'meet']);
    });

    test('old avatars map to the first six looks', () {
      expect(['lens', 'print', 'key', 'map', 'idea', 'notes'].map(lookIdFor), [
        'look_01',
        'look_02',
        'look_03',
        'look_04',
        'look_05',
        'look_06',
      ]);
      expect(lookIdFor('look_08'), 'look_08');
      expect(lookIdFor(null), 'look_01');
    });
  });

  group('VisitRepository (POST /api/visits/{visit}/events)', () {
    test('events outside a lesson go under the visit, in seq order, and '
        'pass the contract', () async {
      final server = FakeServer();
      server.on('POST /api/visits/v1/events', {'accepted': 2});
      var n = 0;
      final visits = VisitRepository(
        ApiClient(
          baseUrl: 'http://test',
          bearer: () => 'device-token',
          client: server.client,
        ),
        deviceId: () => 'dv_test1234',
        appVersion: '0.1.0',
        newId: () => n++ == 0
            ? 'v1'
            : '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}',
        nowMs: () => 1791400000000,
      );
      await visits.record('test1234', [trailOpened, cabinetOpened(2)]);
      final (route, body) = server.calls.single;
      expect(route, 'POST /api/visits/v1/events');
      expect(body['childId'], 'test1234');
      final events = (body['events']! as List).cast<Map>();
      expect(
        [for (final e in events) e['name']],
        ['trail_opened', 'cabinet_opened'],
      );
      expect([for (final e in events) e['seq']], [0, 1]);
      expect(events.every((e) => e['session_id'] == 'v1'), isTrue);
      // the contract's session_id is a uuid: check with one
      expectContract([
        for (final e in visits.written)
          e.withSession('5b0c3f0e-8a51-4c2e-9d3e-2f1a6c7b9e10'),
      ]);
    });

    test('offline: kept and sent again with the next', () async {
      final server = FakeServer();
      var up = false;
      server.routes['POST /api/visits/v1/events'] = (_) =>
          up ? (200, {}) : (503, {'error': 'down'});
      var n = 0;
      final visits = VisitRepository(
        ApiClient(
          baseUrl: 'http://test',
          bearer: () => 'device-token',
          client: server.client,
        ),
        deviceId: () => 'dv_test1234',
        appVersion: '0.1.0',
        newId: () => n++ == 0 ? 'v1' : 'e$n',
      );
      await visits.record('c1', [trailOpened]);
      up = true;
      await visits.record('c1', [cabinetOpened(0)]);
      final last = server.calls.last.$2['events']! as List;
      expect(last, hasLength(2));
    });
  });

  test('SessionRepository.started: the look the repository says', () {
    expect(SessionRepository.defaultLook.avatarId, 'look_01');
  });
}

/// A tutors file with one tutor on (TTR-01: the picker is skipped).
class JourneyConfigTestOne {
  const JourneyConfigTestOne();
  JourneyConfig get config => JourneyConfig.fromYaml(
    tutors: '''
default: teacher_1
enabled: [teacher_1]
tutors:
  - {id: teacher_1, kind: grown_up_teacher, name: null, default_voice: voice_a}
  - {id: robot, kind: robot, name: null, default_voice: voice_c}
''',
  );
}
