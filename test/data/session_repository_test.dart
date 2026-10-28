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
    await repo.record('s1', 1, const [step]);
    expect(api.received.map((e) => (e.sessionId, e.seq)), [('s1', 1)]);
    expect(await db.unsent(), isEmpty);
    repo.dispose();
    await db.close();
  });

  test('failed sync retries and then marks sent', () async {
    final db = await memoryOutbox();
    fakeAsync((async) {
      final api = FakeApi()..failNext = 1;
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
      repo.record('s1', 1, const [step]);
      async.flushMicrotasks();
      expect(api.received, isEmpty);
      async.elapse(const Duration(seconds: 2));
      expect(api.received.map((e) => e.seq), [1]);
      repo.dispose();
    });
    await db.close();
  });

  test('offline lesson syncs in order later', () async {
    final db = await memoryOutbox();
    fakeAsync((async) {
      final api = FakeApi()..failNext = 1000;
      final repo = SessionRepository(
        db: db,
        api: api,
        identity: testIdentity,
        nowMs: () => 5,
      );
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
    final api = FakeApi()..failNext = 2;
    final repo = SessionRepository(
      db: db,
      api: api,
      identity: testIdentity,
      nowMs: () => 5,
    );
    await repo.record('a', 1, const [step]);
    await repo.record('b', 1, const [step]);
    await repo.syncNow();
    expect(api.batches.map((b) => b.$1), ['a', 'b']);
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
      await repo.record('s-${problem.id}', 0, events);
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
        resumeSessionId: 's-lemon',
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
      ));
      repo.dispose();
    });
  });
}
