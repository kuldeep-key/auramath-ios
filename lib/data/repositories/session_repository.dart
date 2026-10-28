import 'dart:async';
import 'dart:math' as math;

import 'package:auramath_engine/auramath_engine.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson_event.dart';
import '../services/api.dart';
import '../services/outbox_db.dart';

/// The lesson's record: saves every event on the phone first, then sends it,
/// retrying until the server has it. A lesson never waits on the network.
class SessionRepository {
  SessionRepository({
    required this._db,
    required this._api,
    required this.identity,
    String Function()? newId,
    int Function()? nowMs,
  }) : _newId = newId ?? const Uuid().v4,
       _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final OutboxDb _db;
  final Api _api;
  final Identity identity;
  final String Function() _newId;
  final int Function() _now;

  Timer? _retry;
  int _failures = 0;
  bool _syncing = false;
  bool _again = false;

  /// 2 s, doubling, capped at 30 s.
  static Duration retryDelay(int failures) =>
      Duration(seconds: math.min(30, 2 << math.min(failures - 1, 4)));

  /// Saves [events] as seq [firstSeq] onwards, then tries to send them.
  Future<void> record(
    String sessionId,
    int firstSeq,
    List<SpecEvent> events,
  ) async {
    final at = _now();
    for (final (i, e) in events.indexed) {
      await _db.insert(
        LessonEvent(
          eventId: _newId(),
          sessionId: sessionId,
          seq: firstSeq + i,
          at: at,
          name: e.name,
          childRef: identity.childRef,
          deviceId: identity.deviceId,
          appVersion: identity.appVersion,
          payload: e.payload,
        ),
      );
    }
    await syncNow();
  }

  /// Sends everything unconfirmed, one batch per session, oldest first.
  Future<void> syncNow() async {
    if (_syncing) {
      _again = true;
      return;
    }
    _syncing = true;
    _retry?.cancel();
    try {
      do {
        _again = false;
        for (
          var batch = await _db.unsent();
          batch.isNotEmpty;
          batch = await _db.unsent()
        ) {
          for (final (sessionId, events) in _bySession(batch)) {
            await _api.sendEvents(sessionId, events);
            await _db.markSent(events);
          }
        }
      } while (_again);
      _failures = 0;
    } on ApiException {
      _failures++;
      _retry = Timer(retryDelay(_failures), syncNow);
    } finally {
      _syncing = false;
    }
  }

  /// A session's events from its latest `problem_shown` on (what a resume
  /// replays), and the last seq saved, which the next event follows.
  Future<({List<SpecEvent> events, int lastSeq})> resume(
    String sessionId,
  ) async {
    final all = await _db.forSession(sessionId);
    final from = all.lastIndexWhere((e) => e.name == 'problem_shown');
    return (
      events: [for (final e in all.skip(math.max(from, 0))) e.spec],
      lastSeq: all.isEmpty ? -1 : all.last.seq,
    );
  }

  /// Where Home's Keep going leads, read from the log: back into the last
  /// case if it isn't finished, else on to the problem the engine chose.
  /// Null when nothing is saved or the pack no longer has that problem.
  Future<({String problemId, String? resumeSessionId})?> whereNext(
    Pack pack,
  ) async {
    final sessionId = await _db.lastSessionId();
    if (sessionId == null) return null;
    final (:events, lastSeq: _) = await resume(sessionId);
    final shown = events.firstOrNull;
    final problem = shown?.name == 'problem_shown'
        ? pack.problems[shown!.payload['problem_id']]
        : null;
    if (problem == null) return null;
    var state = initialState();
    for (final input in inputsFrom(pack, problem, events)) {
      final r = step(pack, problem, state, input);
      state = r.state;
      for (final d in r.decisions) {
        final next = switch (d) {
          Solved(:final nextProblemId) => nextProblemId,
          SwitchProblem(:final problemId) => problemId,
          _ => null,
        };
        if (next != null) {
          return pack.problems.containsKey(next)
              ? (problemId: next, resumeSessionId: null)
              : null;
        }
      }
    }
    return (problemId: problem.id, resumeSessionId: sessionId);
  }

  void dispose() => _retry?.cancel();

  static List<(String, List<LessonEvent>)> _bySession(List<LessonEvent> batch) {
    final groups = <String, List<LessonEvent>>{};
    for (final e in batch) {
      (groups[e.sessionId] ??= []).add(e);
    }
    return [for (final g in groups.entries) (g.key, g.value)];
  }
}
