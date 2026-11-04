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
      version: 3,
      onCreate: (db, _) async {
        await _create(db);
        await _createV3(db);
      },
      onUpgrade: (db, from, _) async {
        // v1 held the pre-contract event shape; no real family has used the
        // app, so it is dropped rather than migrated.
        if (from < 2) {
          await db.execute('DROP TABLE IF EXISTS events');
          await _create(db);
        }
        if (from < 3) await _createV3(db);
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

  /// Unconfirmed events, oldest first.
  Future<List<LessonEvent>> unsent({int limit = 50}) async => [
    for (final r in await _db.query(
      'events',
      where: 'sent = 0',
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
  Future<String?> lastSessionId() async {
    final rows = await _db.query(
      'events',
      columns: ['session_id'],
      orderBy: 'rowid DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['session_id']! as String;
  }

  /// Forgets every lesson on this phone (DEV-06).
  Future<void> clear() async {
    await _db.delete('events');
    await _db.delete('ended');
  }

  Future<void> close() => _db.close();

  LessonEvent _row(Map<String, Object?> r) => LessonEvent.fromJson(
    jsonDecode(r['body']! as String) as Map<String, Object?>,
  );
}
