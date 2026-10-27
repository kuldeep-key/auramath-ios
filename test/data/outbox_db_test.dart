import 'package:auramath/data/models/lesson_event.dart';
import 'package:auramath/data/services/outbox_db.dart';
import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

LessonEvent ev(
  String session,
  int seq, [
  LessonInput input = const Started(),
]) => LessonEvent.fromInput(
  sessionId: session,
  seq: seq,
  at: 1000 + seq,
  packVersion: 'sample-1',
  problemId: 'lemon',
  input: input,
);

void main() {
  late OutboxDb db;
  setUp(() async => db = await memoryOutbox());
  tearDown(() => db.close());

  test('LessonEvent.toJson matches the backend wire event', () {
    expect(ev('s1', 3, const NumberEntered(79)).toJson(), {
      'seq': 3,
      'at': 1003,
      'name': 'numberEntered',
      'detail': '',
      'data': {
        'value': 79,
        'packVersion': 'sample-1',
        'problemId': 'lemon',
        'schemaVersion': 1,
      },
    });
  });

  test('an event gives back its input', () {
    final back = ev('s1', 1, const PieceDropped(Piece.gap, Target.barB)).input;
    expect(
      inputToJson(back),
      inputToJson(const PieceDropped(Piece.gap, Target.barB)),
    );
  });

  test('duplicate session_id+seq is ignored', () async {
    await db.insert(ev('s1', 1));
    await db.insert(ev('s1', 1, const BarADrawn()));
    final rows = await db.forSession('s1');
    expect(rows, hasLength(1));
    expect(rows.single.name, 'started');
  });

  test('markSent removes from unsent', () async {
    await db.insert(ev('s1', 1));
    await db.insert(ev('s1', 2));
    await db.markSent([ev('s1', 1)]);
    expect((await db.unsent()).map((e) => e.seq), [2]);
  });

  test('unsent keeps insert order and respects the limit', () async {
    for (var i = 1; i <= 5; i++) {
      await db.insert(ev('s1', i));
    }
    expect((await db.unsent(limit: 3)).map((e) => e.seq), [1, 2, 3]);
  });
}
