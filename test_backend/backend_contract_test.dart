// The app's real data layer against a running backend, over HTTP: no
// fakes between ApiClient and the server. Opt-in, outside `flutter test`'s
// default test/ folder:
//
//   AURAMATH_API=http://127.0.0.1:8095 \
//   AURAMATH_SCHEMA=<backend>/spec/contracts/events.schema.json \
//   AURAMATH_CLOCK=<serve_simclock's SIM_CLOCK_FILE> \
//   flutter test test_backend/backend_contract_test.dart
//
// The backend runs locally on the memory store with the demo operator token
// (never a deployed one). AURAMATH_CLOCK, when set, is moved an hour on at
// the end so the sitting's note is due.
import 'dart:convert';
import 'dart:io';

import 'package:auramath/data/models/lesson_event.dart';
import 'package:auramath/data/repositories/grown_up_repository.dart';
import 'package:auramath/data/repositories/recent_notes_repository.dart';
import 'package:auramath/data/repositories/report_email_repository.dart';
import 'package:auramath/data/repositories/rewards_repository.dart';
import 'package:auramath/data/repositories/session_repository.dart';
import 'package:auramath/data/services/api_client.dart';
import 'package:auramath/data/services/key_store.dart';
import 'package:auramath/data/services/outbox_db.dart';
import 'package:auramath/ui/features/lesson/view_models/lesson_view_model.dart';
import 'package:auramath/ui/features/lesson/view_models/sitting.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:json_schema/json_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test/ui/features/lesson/fakes.dart' show FakeVoice, samplePack;

final base = Platform.environment['AURAMATH_API'] ?? 'http://127.0.0.1:8095';
final schemaPath =
    Platform.environment['AURAMATH_SCHEMA'] ??
    'packages/auramath_engine/test/contract/events.schema.json';
final clockPath = Platform.environment['AURAMATH_CLOCK'];
const operator = 'demo-operator-token';
const minute = 60 * 1000;

/// Every call made, as "METHOD /path -> status".
final calls = <String>[];

class _Counting extends http.BaseClient {
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final r = await _inner.send(request);
    calls.add('${request.method} ${request.url.path} -> ${r.statusCode}');
    return r;
  }
}

ApiClient client(String? token) =>
    ApiClient(baseUrl: base, bearer: () => token, client: _Counting());

final template = ComparisonTemplate.fromYaml(
  File('assets/spec/comparison-two-step.yaml').readAsStringSync(),
);

/// The input a child gives at [vm]'s step: the right one, except at
/// find_unknown, where a swapped-digit answer and a plain wrong one come
/// first (each judged by the server's decisions).
LessonInput inputFor(LessonViewModel vm, Set<String> tried) {
  final p = vm.problem;
  final s = vm.state;
  LessonInput choose(String stepId) => choiceOptions(
    vm.pack,
    p,
    stepId,
  ).firstWhere((o) => o.right).input(stepId);
  return switch (s.step) {
    LessonStep.question => const Started(),
    LessonStep.nameQuantities => choose('name_quantities'),
    LessonStep.drawA => const BarADrawn(),
    LessonStep.placeB => const BarBPlaced(),
    LessonStep.sizeB => BarBSized(
      p.big == BigSide.a ? Relation.shorter : Relation.taller,
    ),
    LessonStep.placeGap => const PieceDropped(Piece.gap, Target.gapSlot),
    LessonStep.placeTotal => const PieceDropped(Piece.total, Target.totalSlot),
    LessonStep.chooseOp => choose('choose_operation'),
    LessonStep.findB
        when tried.add('transposed') && swapped(p.bValue) != null =>
      NumberEntered(swapped(p.bValue)!),
    LessonStep.findB when tried.add('wrong') => NumberEntered(p.bValue + 1),
    LessonStep.findB => NumberEntered(p.bValue),
    LessonStep.findTotal => NumberEntered(p.total),
    LessonStep.sideLesson => const SideLessonDone(completed: false),
    _ => throw StateError('no input for ${s.step}'),
  };
}

/// [n] with two digits swapped, when that is another number.
int? swapped(int n) {
  final d = '$n'.split('');
  for (var i = 0; i + 1 < d.length; i++) {
    if (d[i] != d[i + 1] && !(i == 0 && d[i + 1] == '0')) {
      final t = [...d]
        ..[i] = d[i + 1]
        ..[i + 1] = d[i];
      return int.parse(t.join());
    }
  }
  return null;
}

void main() {
  late final JsonSchema schema;
  late final ApiClient parent;
  late final String childId;
  final rejected = <String>[];

  Future<String> pairDevice(String label) async {
    final code =
        (await parent.post('/api/devices/pairing') as Map)['code'] as String;
    return (await client(
              null,
            ).post('/api/devices/redeem', {'code': code, 'label': label})
            as Map)['token']
        as String;
  }

  ({SessionRepository repo, OutboxDb db}) phone(
    OutboxDb db,
    String token,
    String deviceId,
  ) => (
    repo: SessionRepository(
      db: db,
      api: HttpApi(client(token)),
      identity: (
        deviceId: deviceId,
        appVersion: '0.1.0',
        isDemo: false,
        contentVersions: const {'policy': '0.3.0'},
      ),
      template: template,
      onRejected: (s, r) => rejected.addAll(r.map((x) => '$s $x')),
      onFailed: (s, m) => rejected.add('failed $s $m'),
    ),
    db: db,
  );

  LessonViewModel lesson(
    Pack pack,
    SessionRepository repo, {
    String problemId = LessonViewModel.newProblem,
    String? carryFrom,
    String? sessionId,
  }) =>
      LessonViewModel(
          pack: pack,
          problemId: problemId,
          sessionId: sessionId,
          sessions: repo,
          voice: FakeVoice(),
          openSession: () => repo.open(childId: childId),
          nextProblem: (s, {level}) => repo.nextProblem(pack, s, level: level),
          sitting: Sitting(capMs: 30 * minute),
          tickEvery: null,
        )
        ..childId = childId
        ..askDecisions = true
        ..carryFrom = carryFrom;

  Future<void> playUntil(
    LessonViewModel vm,
    bool Function(LessonStep) stop,
  ) async {
    final tried = <String>{};
    for (var i = 0; i < 40 && !stop(vm.state.step); i++) {
      await vm.send(inputFor(vm, tried));
    }
    expect(stop(vm.state.step), isTrue, reason: 'stuck at ${vm.state.step}');
  }

  void expectContract(Iterable<LessonEvent> events) {
    for (final e in events) {
      final r = schema.validate(e.toJson());
      expect(r.isValid, isTrue, reason: '${e.name}: ${r.errors}');
    }
  }

  setUpAll(() async {
    schema = JsonSchema.create(jsonDecode(File(schemaPath).readAsStringSync()));
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final p =
        await client(operator).post('/api/admin/parents', {
              'email': 'contract-$stamp@example.test',
            })
            as Map;
    parent = client(p['token'] as String);
    await parent.post('/api/children', {
      'displayName': 'Rae',
      'age': 8,
      'schoolYear': 'Year 3',
      'startingPoint': 'chosen',
    });
    final kids = (await parent.get('/api/children') as Map)['children'] as List;
    childId = (kids.single as Map)['id'] as String;
  });

  test('the app and the backend, end to end over HTTP', () async {
    final pack = samplePack();
    final dbA = await OutboxDb.open(inMemoryDatabasePath);
    final a = phone(dbA, await pairDevice('Phone A'), 'dv_phonea0001');

    // 1. a lesson: open, the starting check, a problem, a full case
    final first = lesson(pack, a.repo);
    await first.start();
    expect(first.inStartingCheck, isTrue, reason: 'a new child is checked');
    while (first.inStartingCheck) {
      final sum = first.startingSums[first.startingAt];
      await first.answerStarting(sum.answer);
    }
    expect(first.ready, isTrue);
    final s1 = first.sessionId;
    expect(a.repo.sittingOf(s1), isNotNull);
    expect(first.problem.steps, isNotNull, reason: 'served with its steps');
    await playUntil(first, (s) => s == LessonStep.solved);
    await Future<void>.delayed(const Duration(seconds: 1));
    final badge1 = a.repo.badgeFor(s1);
    expectContract(await dbA.forSession(s1));

    // a decision asked directly, for a swapped-digit answer: recheck only
    final p = first.problem;
    final judged =
        await a.repo.decide(s1, {
              'point': 'after_step',
              'allowed': ['continue'],
              'rulesDefault': 'continue',
              'step': {
                'problemId': p.id,
                'level': p.level,
                'relation': p.big == BigSide.a ? 'taller' : 'shorter',
                'A': p.aValue,
                'D': p.diff,
                'stepId': 'find_unknown',
                'value': swapped(p.bValue) ?? p.bValue + 9,
                'phoneVerdict': 'incorrect',
                'phoneErrorType': 'transposition',
              },
            })
            as Map;

    // 2. the next lesson: something easier, then time's up mid-case
    final second = lesson(pack, a.repo);
    await second.start();
    final before = second.sessionId;
    await second.send(const Started());
    await second.send(const EasierTaken());
    final s2 = second.sessionId;
    expect(s2, isNot(before), reason: 'the easier case has its own session');
    expect(second.problem.variant, 'easier');
    await playUntil(second, (s) => s == LessonStep.placeGap);
    final stoppedAt = second.state;
    await second.callItADay();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    second.dispose();

    // 3. the next day on phone A: carried on in the server's continuation
    final where = (await a.repo.whereNext(pack, childId: childId))!;
    expect(where.carryFrom, s2);
    final third = lesson(
      pack,
      a.repo,
      problemId: where.problemId,
      carryFrom: where.carryFrom,
    );
    await third.start();
    final s3 = third.sessionId;
    expect(s3, isNot(s2), reason: 'continuedIn names a new session');
    expect(a.repo.live(s2), s3);
    expect(third.state.step, stoppedAt.step, reason: 'the board is kept');
    await third.send(inputFor(third, {}));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // 4. phone B, mid-continuation: the whole board comes back
    final dbB = await OutboxDb.open(
      '${Directory.systemTemp.createTempSync('outbox').path}/b.db',
    );
    final b = phone(dbB, await pairDevice('Phone B'), 'dv_phoneb0001');
    final onB = (await b.repo.whereNext(samplePack(), childId: childId))!;
    expect(onB.resumeSessionId, s3);
    final (:events, lastSeq: _) = await b.repo.resume(s3);
    final bProblem = (await b.repo.whereNext(samplePack(), childId: childId))!;
    expect(bProblem.problemId, third.problem.id);
    final rebuilt = replay(
      third.pack,
      third.problem,
      inputsFrom(third.pack, third.problem, events),
    );
    expect(rebuilt.step, third.state.step);
    expect(rebuilt.barA, isTrue);

    // 5. phone A finishes it: the continuation ends, with its badge
    await playUntil(third, (s) => s == LessonStep.solved);
    await Future<void>.delayed(const Duration(seconds: 1));
    final badge3 = a.repo.badgeFor(s3);
    for (final s in [s1, s2, s3]) {
      expectContract(await dbA.forSession(s));
    }
    expect(await dbA.unsent(), isEmpty, reason: 'everything reached it');

    // 6. rewards, notes, the report email
    final sessionBadge = await RewardsRepository(
      parent,
    ).sessionBadge(s1, childId: childId);
    final trail = await RewardsRepository(parent).trail(childId);
    final levelBadges = await RewardsRepository(parent).levelBadges(childId);
    if (clockPath != null) {
      File(clockPath!).writeAsStringSync('3600');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await client(operator).post('/api/admin/sessions/sweep');
    }
    final notes = await RecentNotesRepository(
      parent,
      GrownUpRepository(parent, MemoryKeyStore()),
    ).recent(childId);
    final email = ReportEmailRepository(parent);
    await email.setFrequency(ReportFrequency.weekly);
    expect(await email.frequency(), ReportFrequency.weekly);
    await email.setFrequency(ReportFrequency.each);
    expect(await email.frequency(), ReportFrequency.each);
    // the server's own view: the continuation is linked, ended and noted
    final rows = {
      for (final r
          in ((await parent.get('/api/sessions', query: {'limit': '20'})
                      as Map)['sessions']
                  as List)
              .cast<Map>())
        r['id']: r,
    };
    expect(rows[s3]?['resumedFrom'], s2);
    expect(rows[s3]?['endedAt'], isNotNull);
    expect(rows[s2]?['endedAt'], isNotNull);
    final refused =
        await client(operator).get('/api/admin/events/rejected') as Map;

    // ignore: avoid_print
    print(
      const JsonEncoder.withIndent('  ').convert({
        'calls': calls.length,
        'byRoute': {
          for (final c
              in calls
                  .map((c) => c.replaceAll(RegExp(r'/[0-9a-f-]{36}'), '/{id}'))
                  .toSet())
            c: calls
                .map((c) => c.replaceAll(RegExp(r'/[0-9a-f-]{36}'), '/{id}'))
                .where((x) => x == c)
                .length,
        },
        'rejectedByServer': rejected,
        'serverRejectionCounters': refused,
        'sessions': {'first': s1, 'timeUp': s2, 'continuation': s3},
        'badgeFirst': badge1?.name,
        'badgeContinuation': badge3?.name,
        'rewardsSessionBadge': sessionBadge?.name,
        'trailStops': trail?.stops.length,
        'levelBadges': levelBadges.length,
        'notes': notes.length,
        'directDecision': {
          'action': judged['action'],
          'help': (judged['decision'] as Map?)?['help'],
        },
        'firstProblemVariant': first.problem.variant,
      }),
    );
    expect(rejected, isEmpty);
    expect(calls.where((c) => RegExp(r'-> [45]\d\d$').hasMatch(c)), isEmpty);
    first.dispose();
    third.dispose();
  });
}
