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
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE events(
          session_id TEXT NOT NULL,
          seq INTEGER NOT NULL,
          at INTEGER NOT NULL,
          name TEXT NOT NULL,
          detail TEXT NOT NULL,
          data TEXT NOT NULL,
          sent INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY(session_id, seq)
        )'''),
    );
    return OutboxDb._(db);
  }

  final Database _db;

  Future<void> insert(LessonEvent e) => _db.insert('events', {
    'session_id': e.sessionId,
    'seq': e.seq,
    'at': e.at,
    'name': e.name,
    'detail': e.detail,
    'data': jsonEncode(e.data),
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

  LessonEvent _row(Map<String, Object?> r) => LessonEvent(
    sessionId: r['session_id']! as String,
    seq: r['seq']! as int,
    at: r['at']! as int,
    name: r['name']! as String,
    detail: r['detail']! as String,
    data: jsonDecode(r['data']! as String) as Map<String, Object?>,
  );
}
