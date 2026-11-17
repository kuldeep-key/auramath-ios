import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson_event.dart';
import '../services/api.dart';
import '../services/api_client.dart';

/// The events a child writes outside a lesson (D-60 A): `trail_opened`,
/// `read_aloud_played` (Meet, Home, the pickers), `cabinet_opened`,
/// `badge_opened`, `badge_shown` and `celebration_shown`.
///
/// They go to `POST /api/visits/{visitId}/events` as `{childId, events}`,
/// each event's `session_id` the visit's id: a UUID made once per app open
/// (a visit is not a session, SES-05). The server is idempotent on (visit,
/// seq), so a batch that didn't arrive is sent again whole with the next
/// one. Never blocks a screen and never shows an error: a reward or a
/// trail opened is not worth a child waiting for.
class VisitRepository {
  VisitRepository(
    this._client, {
    required this.deviceId,
    required this.appVersion,
    String Function()? newId,
    int Function()? nowMs,
  }) : _newId = newId ?? const Uuid().v4,
       _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch) {
    visitId = _newId();
  }

  final ApiClient _client;
  final String Function() deviceId;
  final String appVersion;
  final String Function() _newId;
  final int Function() _now;

  /// This app open's visit.
  late final String visitId;

  int _seq = 0;

  /// Written, not yet taken by the server, by child.
  final _waiting = <String, List<LessonEvent>>{};

  /// Every event written this visit (newest last), for tests and the
  /// event check.
  @visibleForTesting
  final written = <LessonEvent>[];

  /// Logs [events] for [childId] and sends what waits. Null child (no one
  /// chosen yet): nothing to log.
  Future<void> record(String? childId, List<SpecEvent> events) async {
    if (childId == null || events.isEmpty) return;
    final at = _now();
    final mine = _waiting[childId] ??= [];
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
      mine.add(event);
      written.add(event);
    }
    await _send(childId);
  }

  bool _sending = false;

  Future<void> _send(String childId) async {
    if (_sending) return;
    _sending = true;
    try {
      while (_waiting[childId]?.isNotEmpty ?? false) {
        final batch = [..._waiting[childId]!];
        await _client.post('/api/visits/$visitId/events', {
          'childId': childId,
          'events': [for (final e in batch) e.toJson()],
        });
        _waiting[childId]!.removeRange(0, batch.length);
      }
    } on ApiException catch (e) {
      // offline or refused: kept for the next one (a 404 is a server
      // before visits, which never takes them)
      if (e.status == 404 || e.status == 422) _waiting[childId]?.clear();
      debugPrint('visit events not sent: $e');
    } finally {
      _sending = false;
    }
  }
}
