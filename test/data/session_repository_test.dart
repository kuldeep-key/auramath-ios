import 'package:auramath/data/repositories/session_repository.dart';
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
      );
      expect(await repo.whereNext(pack), (
        problemId: 'lemon',
        resumeSessionId: 'srv',
        startedOn: 'Phone A',
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
      );
      expect((await repo.whereNext(pack))?.startedOn, isNull);
      repo.dispose();
      await db.close();
    });
  });
}
