import 'package:auramath/data/services/outbox_db.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late OutboxDb db;
  setUp(() async => db = await memoryOutbox());
  tearDown(() => db.close());

  test(
    'a saved event passes the backend schema and reads back the same',
    () async {
      await db.insert(ev('s1', 0));
      final back = (await db.forSession('s1')).single;
      expect(back.toJson(), ev('s1', 0).toJson());
      expectContract([back]);
    },
  );

  test('duplicate session_id+seq is ignored', () async {
    await db.insert(ev('s1', 1));
    await db.insert(ev('s1', 1, 'step_committed'));
    final rows = await db.forSession('s1');
    expect(rows, hasLength(1));
    expect(rows.single.name, 'step_entered');
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
