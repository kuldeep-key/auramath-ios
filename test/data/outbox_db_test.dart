import 'dart:convert';
import 'dart:io';

import 'package:auramath/data/models/lesson_event.dart';
import 'package:auramath/data/services/outbox_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  test("B2: lastSessionId for a child is that child's newest", () async {
    LessonEvent of(String s, int seq, String ref) => LessonEvent(
      eventId: '$s-$seq',
      sessionId: s,
      seq: seq,
      at: seq,
      name: 'step_entered',
      childRef: ref,
      deviceId: 'dv_test1234',
      appVersion: '0.1.0',
      payload: const {},
    );
    await db.insert(of('a1', 0, 'ch_a'));
    await db.insert(of('b1', 0, 'ch_b'));
    for (var i = 1; i < 450; i++) {
      await db.insert(of('a2', i, 'ch_a'));
    }
    expect(await db.lastSessionId(), 'a2');
    expect(await db.lastSessionId(childRef: 'ch_a'), 'a2');
    expect(await db.lastSessionId(childRef: 'ch_b'), 'b1');
    expect(await db.lastSessionId(childRef: 'ch_c'), isNull);
  });

  test(
    'H8: a dead event is kept but never unsent; v4 phones upgrade',
    () async {
      await db.insert(ev('s1', 1));
      await db.insert(ev('s1', 2));
      await db.markDead([ev('s1', 1)]);
      expect((await db.unsent()).map((e) => e.seq), [2]);
      expect(await db.forSession('s1'), hasLength(2));

      // a phone on the v4 outbox keeps its unsent events
      final path = '${Directory.systemTemp.createTempSync().path}/outbox.db';
      final old = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (d, _) => d.execute('''
          CREATE TABLE events(
            session_id TEXT NOT NULL,
            seq INTEGER NOT NULL,
            body TEXT NOT NULL,
            sent INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY(session_id, seq)
          )'''),
        ),
      );
      await old.insert('events', {
        'session_id': 's9',
        'seq': 0,
        'body': jsonEncode(ev('s9', 0).toJson()),
      });
      await old.close();
      final upgraded = await OutboxDb.open(path);
      expect((await upgraded.unsent()).map((e) => e.sessionId), ['s9']);
      await upgraded.close();
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

  test('all lists every session, oldest first', () async {
    await db.insert(ev('s1', 0));
    await db.insert(ev('s2', 0));
    await db.insert(ev('s1', 1));
    expect(
      [for (final e in await db.all()) (e.sessionId, e.seq)],
      [('s1', 0), ('s2', 0), ('s1', 1)],
    );
  });

  test("childRefFor matches the server's child_ref", () {
    // the dev backend made ch_cdfd177903f445f291df1f4acb1de88c for this id
    expect(
      childRefFor('cdfd1779-03f4-45f2-91df-1f4acb1de88c'),
      'ch_cdfd177903f445f291df1f4acb1de88c',
    );
  });
}
