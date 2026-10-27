import 'package:auramath/data/repositories/session_repository.dart';
import 'package:auramath/data/services/fake_api.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('retryDelay is 2,4,8,16,30,30 s', () {
    expect(
      [for (var f = 1; f <= 6; f++) SessionRepository.retryDelay(f).inSeconds],
      [2, 4, 8, 16, 30, 30],
    );
  });

  test('a recorded event is sent', () async {
    final db = await memoryOutbox();
    final api = FakeApi();
    final repo = SessionRepository(db: db, api: api, nowMs: () => 5);
    await repo.record('s1', 1, 'sample-1', 'lemon', const Started());
    expect(api.received.map((e) => (e.sessionId, e.seq)), [('s1', 1)]);
    expect(await db.unsent(), isEmpty);
    repo.dispose();
    await db.close();
  });

  test('failed sync retries and then marks sent', () async {
    final db = await memoryOutbox();
    fakeAsync((async) {
      final api = FakeApi()..failNext = 1;
      final repo = SessionRepository(db: db, api: api, nowMs: () => 5);
      repo.record('s1', 1, 'sample-1', 'lemon', const Started());
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
      final repo = SessionRepository(db: db, api: api, nowMs: () => 5);
      for (var seq = 1; seq <= 5; seq++) {
        repo.record('s1', seq, 'sample-1', 'lemon', const BarADrawn());
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
    final repo = SessionRepository(db: db, api: api, nowMs: () => 5);
    await repo.record('a', 1, 'sample-1', 'lemon', const Started());
    await repo.record('b', 1, 'sample-1', 'lemon', const Started());
    await repo.syncNow();
    expect(api.batches.map((b) => b.$1), ['a', 'b']);
    repo.dispose();
    await db.close();
  });

  test('resume returns inputs in seq order', () async {
    final db = await memoryOutbox();
    final repo = SessionRepository(db: db, api: FakeApi(), nowMs: () => 5);
    await repo.record('s1', 2, 'sample-1', 'lemon', const BarADrawn());
    await repo.record('s1', 1, 'sample-1', 'lemon', const Started());
    final inputs = await repo.resume('s1');
    expect(inputs.map((i) => inputToJson(i)['type']), ['started', 'barADrawn']);
    repo.dispose();
    await db.close();
  });
}
