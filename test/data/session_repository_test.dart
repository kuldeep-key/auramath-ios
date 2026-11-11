import 'package:auramath/data/models/lesson_event.dart';
import 'package:auramath/data/repositories/session_repository.dart';
import 'package:auramath/data/services/api.dart';
import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/features/lesson/fakes.dart' show samplePack;
import 'helpers.dart';

const step = SpecEvent('step_entered', {'step_id': 'draw_known_bar'});

void main() {
  test('retryDelay is 2,4,8,16,30,30 s', () {
    expect(
      [for (var f = 1; f <= 6; f++) SessionRepository.retryDelay(f).inSeconds],
      [2, 4, 8, 16, 30, 30],
    );
  });

  test('retryDelay stays 30 s after many failures', () {
    expect(SessionRepository.retryDelay(63).inSeconds, 30);
    expect(SessionRepository.retryDelay(100).inSeconds, 30);
  });

  test('a recorded event is sent', () async {
    final db = await memoryOutbox();
    final api = FakeApi();
    final repo = SessionRepository(
      db: db,
      api: api,
      identity: testIdentity,
      nowMs: () => 5,
    );
    await repo.open();
    await repo.record('s1', 1, const [step]);
    expect(api.received.map((e) => (e.sessionId, e.seq)), [('s1', 1)]);
    expect(await db.unsent(), isEmpty);
    repo.dispose();
    await db.close();
  });

  test('DAT-03: an event outside a lesson goes after the end of the '
      "child's last lesson; it waits while there is none, or it ended at "
      "time's up", () async {
    final db = await memoryOutbox();
    final api = FakeApi();
    final repo = SessionRepository(
      db: db,
      api: api,
      identity: testIdentity,
      nowMs: () => 1791400000000,
    );
    const avatar = SpecEvent('avatar_chosen', {'avatar_id': 'key'});
    const streak = SpecEvent('streak_moment_shown', {
      'consecutive_days_band': '3_to_6',
    });
    // no lesson yet: it waits
    await repo.recordAfterLesson('test1234', avatar);
    expect(api.received, isEmpty);
    await repo.open(); // s1
    await repo.record('s1', 0, const [
      step,
      SpecEvent('session_ended', {'reason': 'time_up'}),
    ]);
    await repo.recordAfterLesson('test1234', streak);
    expect(
      api.received.map((e) => e.name),
      isNot(contains('avatar_chosen')),
      reason: "after a time_up end it would open the continuation",
    );
    // another child's lesson ends: not theirs
    api.childRef = 'ch_other999';
    await repo.open(); // s2
    await repo.record('s2', 0, const [
      SpecEvent('session_ended', {'reason': 'finished'}),
    ]);
    expect(api.received.where((e) => e.sessionId == 's2'), hasLength(1));
    // the child's next lesson ends: both, after its end, past its seqs
    api.childRef = 'ch_test1234';
    await repo.open(); // s3
    await repo.record('s3', 0, const [
      step,
      SpecEvent('session_ended', {'reason': 'finished'}),
    ]);
    final s3 = api.received.where((e) => e.sessionId == 's3').toList();
    expect(s3.map((e) => (e.name, e.seq)), [
      ('step_entered', 0),
      ('session_ended', 1),
      ('avatar_chosen', 1 + SessionRepository.afterLessonGap),
      ('streak_moment_shown', 2 + SessionRepository.afterLessonGap),
    ]);
    expectContract(api.received);
    // with the last lesson ended cleanly, the next one goes there at once
    await repo.recordAfterLesson(
      'test1234',
      const SpecEvent('badge_shared', {'badge_id': 'tree', 'shared': true}),
    );
    expect(api.received.last.name, 'badge_shared');
    expect(api.received.last.sessionId, 's3');
    repo.dispose();
    await db.close();
  });

  test('the last stopped session and how, for its badge (REW-01)', () async {
    final db = await memoryOutbox();
    final repo = SessionRepository(
      db: db,
      api: FakeApi(),
      identity: testIdentity,
      nowMs: () => 5,
    );
    await repo.open();
    await repo.record('s1', 1, const [step]);
    expect(repo.lastStop.value, isNull);
    await repo.record('s1', 2, const [
      SpecEvent('session_paused', {'reason': 'lock'}),
    ]);
    expect(repo.lastStop.value, (sessionId: 's1', reason: 'paused'));
    await repo.record('s1', 3, const [
      SpecEvent('session_ended', {'reason': 'time_up'}),
    ]);
    expect(repo.lastStop.value, (sessionId: 's1', reason: 'time_up'));
    repo.dispose();
    await db.close();
  });

  test('a refused event is reported and the outbox moves on', () async {
    final db = await memoryOutbox();
    final api = FakeApi()..refuse.add('step_entered');
    final reported = <String>[];
    final repo = SessionRepository(
      db: db,
      api: api,
      identity: testIdentity,
      onRejected: (s, r) => reported.add('$s ${r.join()}'),
      nowMs: () => 5,
    );
    await repo.open();
    await repo.record('s1', 1, const [step]);
    expect(reported, ['s1 step_entered: refused']);
    expect(await db.unsent(), isEmpty);
    expect(repo.online.value, isTrue);
    repo.dispose();
    await db.close();
  });

  test('a session the server ended is announced and never resumed', () async {
    final pack = samplePack();
    final db = await memoryOutbox();
    final api = FakeApi()..ended['s1'] = 'idle';
    final repo = SessionRepository(
      db: db,
      api: api,
      identity: testIdentity,
      nowMs: () => 5,
    );
    final lemon = pack.problems['lemon']!;
    await repo.record(
      await repo.open(),
      0,
      lessonEvents(pack, lemon, const [Started(), BarADrawn()]),
    );
    expect(repo.ended.value, 's1');
    // the case carries on in a new session, its board rebuilt (SES-04)
    expect(await repo.whereNext(pack), (
      problemId: 'lemon',
      resumeSessionId: null,
      startedOn: null,
      carryFrom: 's1',
    ));
    repo.dispose();
    await db.close();
  });

  group('signing out (DEV-06)', () {
    test('sends what is unsent, then keeps no lesson on the phone', () async {
      final db = await memoryOutbox();
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
      await repo.open();
      api.failNext = 1;
      await repo.record('s1', 1, const [step]);
      expect(await db.unsent(), hasLength(1));
      await repo.sendAllThenForget();
      expect(api.received.map((e) => e.seq), [1]);
      expect(await db.all(), isEmpty);
      repo.dispose();
      await db.close();
    });

    test('offline: throws and keeps the unsent work', () async {
      final db = await memoryOutbox();
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
      await repo.open();
      api.failNext = 99;
      await repo.record('s1', 1, const [step]);
      await expectLater(repo.sendAllThenForget(), throwsA(isA<ApiException>()));
      expect(await db.unsent(), hasLength(1));
      repo.dispose();
      await db.close();
    });

    test('forget clears everything without sending', () async {
      final db = await memoryOutbox();
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
      await repo.open();
      api.failNext = 99;
      await repo.record('s1', 1, const [step]);
      await repo.forget();
      expect(await db.all(), isEmpty);
      repo.dispose();
      await db.close();
    });
  });

  test('failed sync retries and then marks sent', () async {
    final db = await memoryOutbox();
    fakeAsync((async) {
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      )..open();
      async.flushMicrotasks();
      api.failNext = 1;
      repo.record('s1', 1, const [step]);
      async.flushMicrotasks();
      expect(api.received, isEmpty);
      async.elapse(const Duration(seconds: 2));
      expect(api.received.map((e) => e.seq), [1]);
      repo.dispose();
    });
    await db.close();
  });

  test('online goes false when sending fails and true once it works', () async {
    final db = await memoryOutbox();
    fakeAsync((async) {
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      )..open();
      async.flushMicrotasks();
      api.failNext = 1;
      expect(repo.online.value, isTrue);
      repo.record('s1', 0, const [step]);
      async.flushMicrotasks();
      expect(repo.online.value, isFalse);
      async.elapse(const Duration(seconds: 2));
      expect(repo.online.value, isTrue);
      repo.dispose();
    });
    await db.close();
  });

  test('offline lesson syncs in order later', () async {
    final db = await memoryOutbox();
    fakeAsync((async) {
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      )..open();
      async.flushMicrotasks();
      api.failNext = 1000;
      for (var seq = 1; seq <= 5; seq++) {
        repo.record('s1', seq, const [step]);
        async.flushMicrotasks();
      }
      async.elapse(const Duration(minutes: 2));
      expect(api.received, isEmpty);
      api.failNext = 0;
      async.elapse(const Duration(seconds: 30));
      expect(api.received.map((e) => e.seq), [1, 2, 3, 4, 5]);
      late List<Object> unsent;
      db.unsent().then((u) => unsent = u);
      async.flushMicrotasks();
      expect(unsent, isEmpty);
      repo.dispose();
    });
    await db.close();
  });

  test('two sessions are sent as separate batches', () async {
    final db = await memoryOutbox();
    final api = FakeApi();
    final repo = SessionRepository(
      db: db,
      api: api,
      identity: testIdentity,
      nowMs: () => 5,
    );
    await repo.open();
    await repo.open();
    api.failNext = 2;
    await repo.record('s1', 1, const [step]);
    await repo.record('s2', 1, const [step]);
    await repo.syncNow();
    expect(api.batches.map((b) => b.$1), ['s1', 's2']);
    repo.dispose();
    await db.close();
  });

  test(
    'resume returns events from the latest problem shown, and the last seq',
    () async {
      final db = await memoryOutbox();
      final repo = SessionRepository(
        db: db,
        api: FakeApi(),
        identity: testIdentity,
        nowMs: () => 5,
      );
      final pack = samplePack();
      final lemon = pack.problems['lemon']!;
      await repo.open();
      await repo.record('s1', 0, [problemShown(lemon), step]);
      final second = [problemShown(lemon), step];
      // a seq can be missing if a save ever failed; the next one must not reuse it
      await repo.record('s1', 5, second);
      final (:events, :lastSeq) = await repo.resume('s1');
      expect(events.map((e) => e.name), ['problem_shown', 'step_entered']);
      expect(lastSeq, 6);
      repo.dispose();
      await db.close();
    },
  );

  group('whereNext', () {
    final pack = samplePack();

    Future<SessionRepository> withLog(List<(String, LessonInput)> log) async {
      final db = await memoryOutbox();
      final repo = SessionRepository(
        db: db,
        api: FakeApi(),
        identity: testIdentity,
        nowMs: () => 5,
      );
      if (log.isEmpty) return repo;
      final problem = pack.problems[log.first.$1]!;
      final events = lessonEvents(pack, problem, [for (final (_, i) in log) i]);
      await repo.record(await repo.open(), 0, events);
      return repo;
    }

    test('nothing saved: no answer', () async {
      final repo = await withLog([]);
      expect(await repo.whereNext(pack), isNull);
      repo.dispose();
    });

    test('an unfinished case is resumed', () async {
      final repo = await withLog([
        ('lemon', const Started()),
        ('lemon', const BarADrawn()),
      ]);
      expect(await repo.whereNext(pack), (
        problemId: 'lemon',
        resumeSessionId: 's1',
        startedOn: null,
        carryFrom: null,
      ));
      repo.dispose();
    });

    test('a switch to something easier goes to that problem', () async {
      final repo = await withLog([
        ('lemon', const Started()),
        ('lemon', const EasierTaken()),
      ]);
      expect(await repo.whereNext(pack), (
        problemId: 'easier',
        resumeSessionId: null,
        startedOn: null,
        carryFrom: null,
      ));
      repo.dispose();
    });

    test('a solved case moves on to the problem the engine chose', () async {
      final repo = await withLog([
        for (final i in const <LessonInput>[
          Started(),
          BarADrawn(),
          BarBPlaced(),
          BarBSized(Relation.shorter),
          PieceDropped(Piece.gap, Target.gapSlot),
          PieceDropped(Piece.total, Target.totalSlot),
          OpChosen(Op.subtract),
          NumberEntered(79),
          NumberEntered(265),
        ])
          ('lemon', i),
      ]);
      expect(await repo.whereNext(pack), (
        problemId: 'shorter',
        resumeSessionId: null,
        startedOn: null,
        carryFrom: null,
      ));
      repo.dispose();
    });
  });

  group('the server knows the unfinished case', () {
    final pack = samplePack();

    test('a case started on another phone is adopted and named', () async {
      final db = await memoryOutbox();
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
      final lemon = pack.problems['lemon']!;
      final spec = lessonEvents(pack, lemon, const [Started(), BarADrawn()]);
      api.openCase = (
        events: [
          for (final (i, e) in spec.indexed)
            ev('srv', i, e.name).withPayload(e.payload),
        ],
        sameDevice: false,
        startedOn: 'Phone A',
        closed: false,
        closedReason: null,
        carried: const [],
      );
      expect(await repo.whereNext(pack), (
        problemId: 'lemon',
        resumeSessionId: 'srv',
        startedOn: 'Phone A',
        carryFrom: null,
      ));
      // adopted as already sent: nothing to resend, and resumable here
      expect(await db.unsent(), isEmpty);
      expect((await repo.resume('srv')).events.length, spec.length);
      repo.dispose();
      await db.close();
    });

    test("this phone's own case doesn't ask to carry on", () async {
      final db = await memoryOutbox();
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
      final lemon = pack.problems['lemon']!;
      final spec = lessonEvents(pack, lemon, const [Started()]);
      api.openCase = (
        events: [
          for (final (i, e) in spec.indexed)
            ev('srv', i, e.name).withPayload(e.payload),
        ],
        sameDevice: true,
        startedOn: 'Phone A',
        closed: false,
        closedReason: null,
        carried: const [],
      );
      expect((await repo.whereNext(pack))?.startedOn, isNull);
      repo.dispose();
      await db.close();
    });
  });

  group('@SES-04 a case the server ended', () {
    final pack = samplePack();

    test('carries on in a new session with its board rebuilt', () async {
      final db = await memoryOutbox();
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
      final lemon = pack.problems['lemon']!;
      final spec = lessonEvents(pack, lemon, const [
        Started(),
        BarADrawn(),
        BarBPlaced(),
      ]);
      // offline ten minutes: the server ended it and serves it as closed
      api.openCase = (
        events: [
          for (final (i, e) in spec.indexed)
            ev('srv', i, e.name).withPayload(e.payload),
        ],
        sameDevice: true,
        startedOn: null,
        closed: true,
        closedReason: 'idle',
        carried: const [],
      );
      final next = await repo.whereNext(pack);
      expect(next, (
        problemId: 'lemon',
        resumeSessionId: null,
        startedOn: null,
        carryFrom: 'srv',
      ));
      // the new session's board is the ended one's
      final id = await repo.open();
      await repo.record(id, 0, [
        const SpecEvent('session_started', {
          'launch_source': 'child_opened',
          'content_versions': <String, String>{},
          'is_demo': false,
        }),
        problemShown(lemon),
      ]);
      await repo.carry(id, 'srv');
      final (:events, :lastSeq) = await repo.resume(id);
      expect(lastSeq, 1, reason: "the new session's own seqs go on");
      final state = replay(pack, lemon, inputsFrom(pack, lemon, events));
      expect(state.step, LessonStep.sizeB);
      expect(state.barB, isTrue);
      repo.dispose();
      await db.close();
    });

    test('nothing begun: it starts again from its question', () async {
      final db = await memoryOutbox();
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
      final lemon = pack.problems['lemon']!;
      final spec = lessonEvents(pack, lemon, const []);
      api.openCase = (
        events: [
          for (final (i, e) in spec.indexed)
            ev('srv', i, e.name).withPayload(e.payload),
        ],
        sameDevice: true,
        startedOn: null,
        closed: true,
        closedReason: 'idle',
        carried: const [],
      );
      expect((await repo.whereNext(pack))?.carryFrom, isNull);
      repo.dispose();
      await db.close();
    });
  });

  group('@SES-01 time up, carried on in the server\'s continuation', () {
    final pack = samplePack();
    final lemon = pack.problems['lemon']!;

    Future<(SessionRepository, FakeApi)> make() async {
      final db = await memoryOutbox();
      final api = FakeApi();
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
      addTearDown(() async {
        repo.dispose();
        await db.close();
      });
      return (repo, api);
    }

    /// The ended session's log as the server serves it: the board, then
    /// `session_ended {time_up}`.
    List<LessonEvent> timeUpBoard(String id) {
      final spec = [
        ...lessonEvents(pack, lemon, const [
          Started(),
          BarADrawn(),
          BarBPlaced(),
        ]),
        const SpecEvent('session_ended', {'reason': 'time_up'}),
      ];
      return [
        for (final (i, e) in spec.indexed)
          ev(id, i, e.name).withPayload(e.payload),
      ];
    }

    test(
      'another phone rebuilds the whole board of an open continuation',
      () async {
        final (repo, api) = await make();
        final before = timeUpBoard('s-ended');
        final n = before.length;
        api.openCase = (
          events: [
            ev('c-open', n, 'session_resumed').withPayload(const {}),
            ev(
              'c-open',
              n + 1,
              'problem_shown',
            ).withPayload(problemShown(lemon).payload),
          ],
          sameDevice: false,
          startedOn: 'Phone A',
          closed: false,
          closedReason: null,
          carried: [before],
        );
        final next = (await repo.whereNext(pack))!;
        expect(next.resumeSessionId, 'c-open');
        expect(next.startedOn, 'Phone A');
        final (:events, :lastSeq) = await repo.resume('c-open');
        expect(lastSeq, n + 1);
        final state = replay(pack, lemon, inputsFrom(pack, lemon, events));
        expect(state.step, LessonStep.sizeB);
        expect(state.barA, isTrue);
      },
    );

    test("another phone carries a time_up board on in the ended session's "
        'continuation', () async {
      final (repo, api) = await make();
      final board = timeUpBoard('s-ended');
      api
        ..openCase = (
          events: board,
          sameDevice: false,
          startedOn: 'Phone A',
          closed: true,
          closedReason: 'time_up',
          carried: const [],
        )
        ..timeUpAt['s-ended'] = board.last.seq;
      final next = (await repo.whereNext(pack))!;
      expect(next.carryFrom, 's-ended');
      final to = await repo.continueAfterTimeUp('s-ended');
      expect(to, 'c-s-ended');
      expect(repo.firstSeq(to!), board.last.seq + 2);
      // posted to the ended session, stored by the server in the new one
      expect(api.batches.single.$1, 's-ended');
      expect(api.batches.single.$2.single.name, 'session_resumed');
      expect(api.batches.single.$2.single.seq, board.last.seq + 1);
      // later calls for either go to the continuation
      expect(repo.live('s-ended'), to);
      await repo.decide('s-ended', const {'point': 'after_step'});
      expect(api.decisions.single.$1, to);
    });

    test('a session not ended at time up gets none', () async {
      final (repo, _) = await make();
      await repo.open();
      await repo.record('s1', 0, const [step]);
      expect(await repo.continueAfterTimeUp('s1'), isNull);
    });

    test('a batch the server moved is linked to its continuation', () async {
      final (repo, api) = await make();
      final id = await repo.open();
      await repo.record(id, 0, [
        problemShown(lemon),
        const SpecEvent('session_ended', {'reason': 'time_up'}),
      ]);
      await repo.record(id, 2, const [step]);
      expect(api.continuations, {id: 'c-$id'});
      expect(repo.live(id), 'c-$id');
    });
  });

  test('@REW-01 the badge the server names as a session ends is kept for '
      'Home', () async {
    final db = await memoryOutbox();
    final api = FakeApi()
      ..badge = (
        badgeId: 'b1',
        kind: 'session',
        name: 'Case cracked',
        forWhat: 'solved',
        draftName: true,
      );
    final repo = SessionRepository(
      db: db,
      api: api,
      identity: testIdentity,
      nowMs: () => 5,
    );
    final id = await repo.open();
    await repo.record(id, 0, const [step]);
    expect(repo.badgeFor(id), isNull);
    await repo.record(id, 1, const [
      SpecEvent('session_ended', {'reason': 'finished'}),
    ]);
    expect(repo.badgeFor(id)?.name, 'Case cracked');
    expect(repo.badgeFor(id)?.forWhat, 'solved');
    repo.dispose();
    await db.close();
  });

  test('@TUT-08 a session keeps its reviewDue and sittingId', () async {
    final db = await memoryOutbox();
    final api = FakeApi()
      ..sittingId = 'sit-1'
      ..reviewDue = const [
        {
          'skill': 'arith.sub-3d-regroup',
          'errorType': 'sub_smaller_from_larger',
          'reason': 'over_limit',
        },
      ];
    final repo = SessionRepository(
      db: db,
      api: api,
      identity: testIdentity,
      nowMs: () => 5,
    );
    final id = await repo.open();
    expect(repo.sittingOf(id), 'sit-1');
    expect(repo.reviewDue(id).single['skill'], 'arith.sub-3d-regroup');
    repo.dispose();
    await db.close();
  });
}
