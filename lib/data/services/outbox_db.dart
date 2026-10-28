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
      version: 2,
      onCreate: (db, _) => _create(db),
      // v1 held the pre-contract event shape; no real family has used the
      // app, so it is dropped rather than migrated.
      onUpgrade: (db, _, _) async {
        await db.execute('DROP TABLE IF EXISTS events');
        await _create(db);
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

  Future<void> close() => _db.close();

  LessonEvent _row(Map<String, Object?> r) => LessonEvent.fromJson(
    jsonDecode(r['body']! as String) as Map<String, Object?>,
  );
}
