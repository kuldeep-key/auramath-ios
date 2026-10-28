import 'dart:async';
import 'dart:math' as math;

import 'package:auramath_engine/auramath_engine.dart';

import '../models/lesson_event.dart';
import '../services/api.dart';
import '../services/outbox_db.dart';

/// The lesson's record: saves every input on the phone first, then sends it,
/// retrying until the server has it. A lesson never waits on the network.
class SessionRepository {
  SessionRepository({
    required this._db,
    required this._api,
    int Function()? nowMs,
  }) : _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final OutboxDb _db;
  final Api _api;
  final int Function() _now;

  Timer? _retry;
  int _failures = 0;
  bool _syncing = false;
  bool _again = false;

  /// 2 s, doubling, capped at 30 s.
  static Duration retryDelay(int failures) =>
      Duration(seconds: math.min(30, 2 << math.min(failures - 1, 4)));

  Future<void> record(
    String sessionId,
    int seq,
    String packVersion,
    String problemId,
    LessonInput input,
  ) async {
    await _db.insert(
      LessonEvent.fromInput(
        sessionId: sessionId,
        seq: seq,
        at: _now(),
        packVersion: packVersion,
        problemId: problemId,
        input: input,
      ),
    );
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

  /// A session's saved inputs, in order, and the seq the next event follows.
  Future<({List<LessonInput> inputs, int lastSeq})> resume(
    String sessionId,
  ) async {
    final events = await _db.forSession(sessionId);
    return (
      inputs: [for (final e in events) e.input],
      lastSeq: events.isEmpty ? 0 : events.last.seq,
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
    final events = await _db.forSession(sessionId);
    final problem = pack.problems[events.first.data['problemId']];
    if (problem == null) return null;
    var state = initialState();
    for (final e in events) {
      final r = step(pack, problem, state, e.input);
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
