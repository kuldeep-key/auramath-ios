import 'dart:async';
import 'dart:math' as math;

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson_event.dart';
import '../services/api.dart';
import '../services/outbox_db.dart';

/// The lesson's record, online-first: the server opens each session and
/// names its child; every event is saved on the phone first, then sent,
/// and held and resent through a dropped connection.
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

  /// The `child_ref` each open session's events carry, from the server.
  final Map<String, String> _childRefs = {};

  /// False while the server can't be reached: the lesson pauses, and the
  /// outbox holds every event until it can (SES-04, online-first).
  final online = ValueNotifier(true);

  Timer? _retry;
  int _failures = 0;

  /// The sync running now; a caller during it waits for it (and the rerun
  /// it asked for), so "Try again" returns with the true connection state.
  Future<void>? _inFlight;
  bool _again = false;

  /// 2 s, doubling, capped at 30 s.
  static Duration retryDelay(int failures) =>
      Duration(seconds: math.min(30, 2 << math.min(failures - 1, 4)));

  /// Asks the server for a new session for [childId] (the lesson needs a
  /// connection to start). Throws [ApiException] when it can't.
  Future<String> open({String? childId}) async {
    final s = await _api.startSession(
      childId: childId,
      isDemo: identity.isDemo,
    );
    _childRefs[s.sessionId] = s.childRef;
    return s.sessionId;
  }

  /// Saves [events] as seq [firstSeq] onwards, then tries to send them.
  Future<void> record(
    String sessionId,
    int firstSeq,
    List<SpecEvent> events,
  ) async {
    final childRef = _childRefs[sessionId] ??=
        (await _db.forSession(sessionId)).firstOrNull?.childRef ??
        (throw StateError('session $sessionId was never opened'));
    final at = _now();
    for (final (i, e) in events.indexed) {
      await _db.insert(
        LessonEvent(
          eventId: _newId(),
          sessionId: sessionId,
          seq: firstSeq + i,
          at: at,
          name: e.name,
          childRef: childRef,
          deviceId: identity.deviceId,
          appVersion: identity.appVersion,
          payload: e.payload,
        ),
      );
    }
    await syncNow();
  }

  /// Sends everything unconfirmed, one batch per session, oldest first.
  Future<void> syncNow() {
    final running = _inFlight;
    if (running != null) {
      _again = true;
      return running;
    }
    return _inFlight = _sync().whenComplete(() => _inFlight = null);
  }

  Future<void> _sync() async {
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
      online.value = true;
    } on ApiException {
      online.value = false;
      _failures++;
      _retry = Timer(retryDelay(_failures), syncNow);
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

  /// Where Home's Keep going leads: back into the child's unfinished case
  /// (the server's, so it follows them across phones; else this phone's
  /// log), or on to the problem the engine chose. Null when nothing is
  /// saved or the pack no longer has that problem.
  Future<({String problemId, String? resumeSessionId, String? startedOn})?>
  whereNext(Pack pack, {String? childId}) async {
    // set when the server's open case was started on another phone
    ({String sessionId, String label})? elsewhere;
    try {
      final open = await _api.resumable(childId: childId);
      if (open != null && open.events.isNotEmpty) {
        // the server's log becomes this phone's, already sent
        for (final e in open.events) {
          await _db.insert(e);
        }
        await _db.markSent(open.events);
        if (!open.sameDevice) {
          elsewhere = (
            sessionId: open.events.first.sessionId,
            label: open.startedOn ?? '',
          );
        }
      }
    } on ApiException {
      // can't ask: this phone's own log still knows its last case
    }
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
              ? (problemId: next, resumeSessionId: null, startedOn: null)
              : null;
        }
      }
    }
    return (
      problemId: problem.id,
      resumeSessionId: sessionId,
      startedOn: elsewhere?.sessionId == sessionId ? elsewhere?.label : null,
    );
  }

  void dispose() {
    _retry?.cancel();
    online.dispose();
  }

  static List<(String, List<LessonEvent>)> _bySession(List<LessonEvent> batch) {
    final groups = <String, List<LessonEvent>>{};
    for (final e in batch) {
      (groups[e.sessionId] ??= []).add(e);
    }
    return [for (final g in groups.entries) (g.key, g.value)];
  }
}
