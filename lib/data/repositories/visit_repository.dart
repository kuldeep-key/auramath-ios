import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson_event.dart';
import '../services/api.dart';
import '../services/api_client.dart';
import '../services/outbox_db.dart';

/// The events a child writes outside a lesson (D-60 A): `trail_opened`,
/// `read_aloud_played` (Meet, Home, the pickers), `cabinet_opened`,
/// `badge_opened`, and `badge_shown` and `celebration_shown` when no
/// sitting of the child's is open (in one, they go with its lesson, H1).
///
/// They go to `POST /api/visits/{visitId}/events` as `{childId, events}`,
/// each event's `session_id` the visit's id: a UUID made once per app open
/// (a visit is not a session, SES-05). The server is idempotent on (visit,
/// seq), so a batch that didn't arrive is sent again whole with the next
/// one. Each is kept in the phone's outbox until the server answers for it,
/// so a killed app doesn't lose it (H5). Never blocks a screen and never
/// shows an error: a reward or a trail opened is not worth a child waiting
/// for.
class VisitRepository {
  VisitRepository(
    this._client, {
    required this.deviceId,
    required this.appVersion,
    OutboxDb? outbox,
    this.onRefused,
    String Function()? newId,
    int Function()? nowMs,
  }) : _db = outbox,
       _newId = newId ?? const Uuid().v4,
       _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch) {
    visitId = _newId();
  }

  final ApiClient _client;
  final String Function() deviceId;
  final String appVersion;
  final String Function() _newId;
  final int Function() _now;

  /// Where waiting events are kept; null: in memory only (a test).
  final OutboxDb? _db;

  /// Events the server refused for good ("why"): a bug in the app or a
  /// contract change, reported. Resending can't fix them.
  final void Function(String message)? onRefused;

  /// This app open's visit.
  late final String visitId;

  int _seq = 0;

  /// Written, not yet taken by the server, by child, with no [_db].
  final _memory = <String, List<LessonEvent>>{};

  /// Every event written this visit (newest last), for tests and the
  /// event check.
  @visibleForTesting
  final written = <LessonEvent>[];

  /// The most sent in one batch.
  static const batchMax = 50;

  /// Logs [events] for [childId] and sends what waits. Null child (no one
  /// chosen yet): nothing to log.
  Future<void> record(String? childId, List<SpecEvent> events) async {
    if (childId == null || events.isEmpty) return;
    final at = _now();
    for (final e in events) {
      final event = LessonEvent(
        eventId: _newId(),
        sessionId: visitId,
        seq: _seq++,
        at: at,
        name: e.name,
        childRef: childRefFor(childId),
        deviceId: deviceId(),
        appVersion: appVersion,
        payload: e.payload,
      );
      written.add(event);
      if (_db case final db?) {
        await db.saveVisitEvent(childId, event);
      } else {
        (_memory[childId] ??= []).add(event);
      }
    }
    await _send(childId);
  }

  /// Sends what earlier app opens left waiting, for every child.
  Future<void> sendWaiting() async {
    for (final id in await _db?.visitChildren() ?? const <String>[]) {
      await _send(id);
    }
  }

  Future<List<LessonEvent>> _waiting(String childId) async =>
      await _db?.visitEvents(childId) ?? [...?_memory[childId]];

  Future<void> _drop(String childId, List<LessonEvent> events) async {
    await _db?.dropVisitEvents(events);
    _memory[childId]?.removeWhere(events.contains);
  }

  /// The children whose events are being sent now: one send at a time
  /// for each, another child's goes on beside it.
  final Set<String> _sending = {};

  Future<void> _send(String childId) async {
    if (!_sending.add(childId)) return;
    try {
      for (
        var waiting = await _waiting(childId);
        waiting.isNotEmpty;
        waiting = await _waiting(childId)
      ) {
        // one visit a batch: its events take that visit's id
        final visit = waiting.first.sessionId;
        final batch = waiting
            .where((e) => e.sessionId == visit)
            .take(batchMax)
            .toList();
        try {
          final reply = await _client.post('/api/visits/$visit/events', {
            'childId': childId,
            'events': [for (final e in batch) e.toJson()],
          });
          // stored but these: a refused event isn't stored, and resending
          // can't change that
          final refused = reply is Map ? reply['rejected'] : null;
          if (refused is List && refused.isNotEmpty) {
            _refused(
              'visit events refused: ${[for (final r in refused.whereType<Map>()) '${r['name']}: ${r['reasons']}'].join('; ')}',
            );
          }
          await _drop(childId, batch);
        } on ApiException catch (e) {
          // offline, or the server may take them later: kept for the next
          if (e.offline ||
              e.status == 408 ||
              e.status == 429 ||
              e.status! >= 500) {
            debugPrint('visit events not sent: $e');
            return;
          }
          // final (a 400 the batch can't pass, no such child): dropped.
          // A 404 from a server before visits and a 403 with consent
          // withdrawn are expected; anything else is reported
          await _drop(childId, batch);
          if (e.status != 404 && e.status != 403) {
            _refused('visit events refused (${e.status}): ${e.message}');
          }
        }
      }
    } finally {
      _sending.remove(childId);
    }
  }

  void _refused(String message) {
    debugPrint(message);
    onRefused?.call(message);
  }
}
