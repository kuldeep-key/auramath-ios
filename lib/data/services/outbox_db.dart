import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/lesson_event.dart';

/// Every event is saved here before anything else, and stays until the server
/// confirms it. Append only: a repeated (session_id, seq) is ignored.
class OutboxDb {
  OutboxDb._(this._db);

  static Future<OutboxDb> open(String path) async {
    final db = await openDatabase(
      path,
      version: 5,
      onCreate: (db, _) async {
        await _create(db);
        await _createV3(db);
        await _createV4(db);
        await _createV5(db);
      },
      onUpgrade: (db, from, _) async {
        // v1 held the pre-contract event shape; no real family has used the
        // app, so it is dropped rather than migrated.
        if (from < 2) {
          await db.execute('DROP TABLE IF EXISTS events');
          await _create(db);
        }
        if (from < 3) await _createV3(db);
        if (from < 4) await _createV4(db);
        if (from < 5) await _createV5(db);
      },
    );
    return OutboxDb._(db);
  }

  final Database _db;

  static Future<void> _create(Database db) => db.execute('''
    CREATE TABLE events(
      session_id TEXT NOT NULL,
      seq INTEGER NOT NULL,
      body TEXT NOT NULL,
      sent INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY(session_id, seq)
    )''');

  /// `ended`: sessions the server ended (offline too long, idle, a full
  /// log); none is resumed, its case starts again in a new session.
  /// `problems`: the server's problems as it sent them, so a case left
  /// part way can be rebuilt after the app restarts.
  static Future<void> _createV3(Database db) async {
    await db.execute('CREATE TABLE ended(session_id TEXT PRIMARY KEY)');
    await db.execute(
      'CREATE TABLE problems(id TEXT PRIMARY KEY, body TEXT NOT NULL)',
    );
  }

  /// `carried`: a session that carries on an ended one's board (time up,
  /// or ended by the server): its case resumes with that session's work
  /// first (SES-01, SES-04).
  static Future<void> _createV4(Database db) => db.execute(
    'CREATE TABLE carried(session_id TEXT PRIMARY KEY, from_id TEXT NOT NULL)',
  );

  /// `dead`: an event whose batch the server refused for good (a 4xx that
  /// isn't 408 or 429: no such session, a body it can't read). It was
  /// reported, is never sent again and doesn't count as unsent, so one bad
  /// batch can't hold up the rest, nor sign-out (H8).
  static Future<void> _createV5(Database db) => db.execute(
    'ALTER TABLE events ADD COLUMN dead INTEGER NOT NULL DEFAULT 0',
  );

  Future<void> saveCarried(String sessionId, String fromId) => _db.insert(
    'carried',
    {'session_id': sessionId, 'from_id': fromId},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<String?> carriedFrom(String sessionId) async =>
      (await _db.query(
            'carried',
            where: 'session_id = ?',
            whereArgs: [sessionId],
          )).firstOrNull?['from_id']
          as String?;

  Future<void> saveProblem(String id, Map<String, Object?> body) => _db.insert(
    'problems',
    {'id': id, 'body': jsonEncode(body)},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<List<Map<String, Object?>>> problems() async => [
    for (final r in await _db.query('problems'))
      (jsonDecode(r['body']! as String) as Map).cast<String, Object?>(),
  ];

  Future<void> markEnded(String sessionId) => _db.insert('ended', {
    'session_id': sessionId,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  Future<bool> isEnded(String sessionId) async => (await _db.query(
    'ended',
    where: 'session_id = ?',
    whereArgs: [sessionId],
  )).isNotEmpty;

  Future<void> insert(LessonEvent e) => _db.insert('events', {
    'session_id': e.sessionId,
    'seq': e.seq,
    'body': jsonEncode(e.toJson()),
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  /// Unconfirmed events, oldest first; none the server refused for good.
  Future<List<LessonEvent>> unsent({int limit = 50}) async => [
    for (final r in await _db.query(
      'events',
      where: 'sent = 0 AND dead = 0',
      orderBy: 'rowid',
      limit: limit,
    ))
      _row(r),
  ];

  Future<void> markSent(List<LessonEvent> events) =>
      _db.transaction((tx) async {
        for (final e in events) {
          await tx.update(
            'events',
            {'sent': 1},
            where: 'session_id = ? AND seq = ?',
            whereArgs: [e.sessionId, e.seq],
          );
        }
      });

  /// The server refused [events]' batch for good: they stay on the phone
  /// (the lesson's own record) but are never sent again (H8).
  Future<void> markDead(List<LessonEvent> events) =>
      _db.transaction((tx) async {
        for (final e in events) {
          await tx.update(
            'events',
            {'dead': 1},
            where: 'session_id = ? AND seq = ?',
            whereArgs: [e.sessionId, e.seq],
          );
        }
      });

  Future<List<LessonEvent>> forSession(String sessionId) async => [
    for (final r in await _db.query(
      'events',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'seq',
    ))
      _row(r),
  ];

  /// Every saved event, oldest first: what this phone has seen of the
  /// child's lessons (the badges, the trail and the streak read it).
  Future<List<LessonEvent>> all() async => [
    for (final r in await _db.query('events', orderBy: 'rowid')) _row(r),
  ];

  /// The session the newest event belongs to, or null when nothing is saved.
  /// With [childRef], the newest of that child's: on a shared phone (or a
  /// child's own phone that copied a sibling's case) another child's
  /// session is never theirs (B2).
  Future<String?> lastSessionId({String? childRef}) async {
    if (childRef == null) {
      final rows = await _db.query(
        'events',
        columns: ['session_id'],
        orderBy: 'rowid DESC',
        limit: 1,
      );
      return rows.isEmpty ? null : rows.single['session_id']! as String;
    }
    // the child is in the body only: read back from the newest, a page at
    // a time, until one of theirs
    const page = 200;
    for (var offset = 0; ; offset += page) {
      final rows = await _db.query(
        'events',
        columns: ['session_id', 'body'],
        orderBy: 'rowid DESC',
        limit: page,
        offset: offset,
      );
      for (final r in rows) {
        if (_row(r).childRef == childRef) return r['session_id']! as String;
      }
      if (rows.length < page) return null;
    }
  }

  /// Forgets every lesson on this phone (DEV-06).
  Future<void> clear() async {
    await _db.delete('events');
    await _db.delete('ended');
    await _db.delete('problems');
    await _db.delete('carried');
  }

  Future<void> close() => _db.close();

  LessonEvent _row(Map<String, Object?> r) => LessonEvent.fromJson(
    jsonDecode(r['body']! as String) as Map<String, Object?>,
  );
}
