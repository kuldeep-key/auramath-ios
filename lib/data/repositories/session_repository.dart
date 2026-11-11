import 'dart:async';
import 'dart:math' as math;

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson_event.dart';
import '../models/server_problem.dart';
import '../services/api.dart';
import '../services/outbox_db.dart';

/// Where the child's next lesson goes: [problemId], resumed in
/// [resumeSessionId], or carried on from the ended [carryFrom] in a new
/// session; [startedOn] names the other phone a case was started on.
typedef WhereNext = ({
  String problemId,
  String? resumeSessionId,
  String? startedOn,
  String? carryFrom,
});

/// A sum from the server's arithmetic generator: its text ("56 - 19 = ?"),
/// answer and arithmetic level (`A6`).
typedef Sum = ({String text, int answer, String level});

/// The lesson's record, online-first: the server opens each session and
/// names its child; every event is saved on the phone first, then sent,
/// and held and resent through a dropped connection.
class SessionRepository {
  SessionRepository({
    required this._db,
    required this._api,
    required this.identity,
    this.onRejected,
    this.onFailed,
    this.template,
    String Function()? newId,
    int Function()? nowMs,
  }) : _newId = newId ?? const Uuid().v4,
       _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final OutboxDb _db;
  final Api _api;
  final Identity identity;
  final String Function() _newId;
  final int Function() _now;

  /// Events the server refused ("name: reasons"): a bug in the app or a
  /// contract change. Resending can't fix them, so they're reported, and
  /// the outbox moves on (the rest of their batch was stored).
  final void Function(String sessionId, List<String> rejected)? onRejected;

  /// A call that failed for a reason other than the network, which the
  /// lesson worked around: reported, so it isn't only a debug line.
  final void Function(String sessionId, String message)? onFailed;

  void failed(String sessionId, String message) {
    debugPrint(message);
    onFailed?.call(sessionId, message);
  }

  /// A spaced check or re-test is due as [sessionId]'s first case.
  bool checkDue(String sessionId) => _checks.containsKey(sessionId);

  /// [sessionId]'s first case is shown: a case fetched ahead in it is never
  /// the check (the next session asks for its own).
  void checkShown(String sessionId) => _checks.remove(sessionId);

  /// Julia's comparison template (served, else bundled): draws a left case
  /// from its ids and numbers, as the first phone did.
  final ComparisonTemplate? template;

  /// The last session the server ended (offline too long, idle, a full
  /// log). The lesson on it shows "we'll keep this for next time".
  final ended = ValueNotifier<String?>(null);

  /// The last session this phone stopped, and how: `session_ended`'s
  /// reason (`finished`, `time_up`, `left`, ...) or `paused`. Home shows
  /// its badge (REW-01: one per session, however it ended).
  final lastStop = ValueNotifier<({String sessionId, String reason})?>(null);

  /// Why the server ended [ended]: `consent` when the family withdrew it,
  /// so the lesson says lessons are paused.
  String? endedWhy;

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
    if (s.checkLevel != null || s.retestDueAt != null) {
      _checks[s.sessionId] = s.checkLevel;
    }
    if (s.startingCheckDue) _startingChecks.add(s.sessionId);
    if (s.leftProblem != null) _left[s.sessionId] = s.leftProblem!;
    return s.sessionId;
  }

  /// A spaced check or re-test due when the session opened: its first
  /// problem only, at the check's level (a re-test has none: the child's
  /// own level).
  final Map<String, String?> _checks = {};

  /// Sessions opened with the starting check still to do (SKL-07).
  final Set<String> _startingChecks = {};
  final Map<String, Map<String, Object?>> _left = {};

  /// The problem the child left last time, which [sessionId] offers back
  /// (once): as this phone drew it, else rebuilt from its `problem_shown`
  /// (ids and numbers) and [template]. Null when there's none, or this
  /// phone's template is another version: then it isn't offered.
  ComparisonProblem? leftProblem(Pack pack, String sessionId) {
    final left = _left.remove(sessionId);
    if (left == null) return null;
    final seen = pack.problems[left['problemId']];
    if (seen != null) return seen;
    final shown = left['problem'] as Map<String, Object?>?;
    final t = template;
    final p = shown == null || t == null ? null : problemFromShown(shown, t);
    if (p != null) _serve(pack, p);
    return p;
  }

  /// The server's next problem for [sessionId], saved on the phone (a
  /// resume rebuilds it) and added to [pack] for the lesson's screens.
  /// [level] asks one at that level ("something easier", the starting
  /// check's placement); else the first problem of a session with a spaced
  /// check or re-test due is that check, at its level, shown with `variant:
  /// check` so the server counts it as the check (SKL-06).
  Future<ComparisonProblem> nextProblem(
    Pack pack,
    String sessionId, {
    String? level,
  }) async {
    final check = level == null && _checks.containsKey(sessionId);
    final checkLevel = _checks[sessionId];
    final j = {
      ...await _api.nextProblem(sessionId, level: level ?? checkLevel),
      if (check) 'variant': 'check',
    };
    // gone only once fetched: offline, Try again asks for the check again
    if (check) _checks.remove(sessionId);
    final problem = problemFromServer(j);
    await _db.saveProblem(problem.id, j);
    _serve(pack, problem);
    return problem;
  }

  /// Smaller sums to practise after a side lesson (TUT-08), as
  /// `(text, answer, level)`, at arithmetic [level] (the server needs one).
  Future<List<Sum>> practiceSums(String childId, {required String level}) =>
      _sums(childId, 'side_lesson', level: level);

  Future<List<Sum>> _sums(
    String childId,
    String purpose, {
    String? level,
  }) async => [
    for (final i in await _api.arithmetic(
      childId,
      purpose: purpose,
      level: level,
    ))
      (
        text: i['text']! as String,
        answer: i['answer']! as int,
        level: i['level']! as String,
      ),
  ];

  /// A set of Quick sums at the child's arithmetic level (LES-16), from
  /// the server's generator (CON-10), as `(text, answer, level)`.
  Future<List<Sum>> quickSums(String childId) => _sums(childId, 'quick_sums');

  /// True while [sessionId]'s starting check is still to do.
  bool startingCheckDue(String sessionId) =>
      _startingChecks.contains(sessionId);

  /// The four starting sums for the child's age (SKL-07), as
  /// `(text, answer, level)`.
  Future<List<Sum>> startingSums(String childId) =>
      _sums(childId, 'starting_check');

  /// Sends how many starting sums were right; the level the server placed
  /// the child at. The check is then done for [sessionId].
  Future<String> sendStartingCheck(
    String sessionId,
    String childId, {
    required int correct,
  }) async {
    final level = await _api.startingCheck(childId, correct: correct);
    _startingChecks.remove(sessionId);
    return level;
  }

  /// The server's choice at a decision point (online only; never queued).
  Future<Map<String, Object?>> decide(
    String sessionId,
    Map<String, Object?> body,
  ) => _api.decide(sessionId, body);

  /// Adds the server's problems saved on this phone to [pack], so a case
  /// left part way resumes after the app restarts.
  Future<void> loadProblems(Pack pack) async {
    for (final j in await _db.problems()) {
      _serve(pack, problemFromServer(j));
    }
  }

  // ponytail: the pack's map doubles as the problem store; give problems
  // their own store if the pack ever becomes read-only
  final List<(Pack, String)> _served = [];
  void _serve(Pack pack, ComparisonProblem p) {
    pack.problems[p.id] = p;
    _served.add((pack, p.id));
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
    for (final e in events) {
      if (e.name == 'session_ended' || e.name == 'session_paused') {
        lastStop.value = (
          sessionId: sessionId,
          reason: e.name == 'session_paused'
              ? 'paused'
              : '${e.payload['reason'] ?? 'finished'}',
        );
      }
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

  /// Signing out (DEV-06): sends what's unsent, then forgets every lesson on
  /// this phone. Throws while anything can't be sent, so no work is lost.
  Future<void> sendAllThenForget() async {
    await syncNow();
    if ((await _db.unsent(limit: 1)).isNotEmpty) {
      throw const ApiException(
        "Some lesson work hasn't reached Auramath yet. Connect to the "
        'internet and try again.',
      );
    }
    await forget();
  }

  /// Forgets every lesson on this phone without sending (the family's data
  /// is already erased on the server).
  Future<void> forget() async {
    _retry?.cancel();
    _childRefs.clear();
    _checks.clear();
    _startingChecks.clear();
    _left.clear();
    for (final (pack, id) in _served) {
      pack.problems.remove(id);
    }
    _served.clear();
    await _db.clear();
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
            final reply = await _api.sendEvents(sessionId, events);
            await _db.markSent(events);
            if (reply.rejected.isNotEmpty) {
              debugPrint('events refused in $sessionId: ${reply.rejected}');
              onRejected?.call(sessionId, reply.rejected);
            }
            if (reply.ended != null) {
              await _db.markEnded(sessionId);
              endedWhy = reply.ended;
              ended.value = sessionId;
            }
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
  /// A session carrying on an ended one's case ([carry]) has that
  /// session's board first, so the case is rebuilt as the child left it.
  Future<({List<SpecEvent> events, int lastSeq})> resume(
    String sessionId,
  ) async {
    final all = await _db.forSession(sessionId);
    final from = all.lastIndexWhere((e) => e.name == 'problem_shown');
    var events = [for (final e in all.skip(math.max(from, 0))) e.spec];
    final carried = await _db.carriedFrom(sessionId);
    // only for the session's first case: a later one is its own
    if (carried != null &&
        from >= 0 &&
        all.indexWhere((e) => e.name == 'problem_shown') == from) {
      final before = (await resume(carried)).events;
      if (before.firstOrNull?.payload['problem_id'] ==
          events.first.payload['problem_id']) {
        events = [
          ...before.where((e) => !e.name.startsWith('session_')),
          ...events.skip(1),
        ];
      }
    }
    return (events: events, lastSeq: all.isEmpty ? -1 : all.last.seq);
  }

  /// [sessionId] carries on [fromId]'s case: time was up there, or the
  /// server ended it, so its work goes on in a new session (SES-01, SES-04).
  Future<void> carry(String sessionId, String fromId) =>
      _db.saveCarried(sessionId, fromId);

  /// Where Home's Keep going leads: back into the child's unfinished case
  /// (the server's, so it follows them across phones; else this phone's
  /// log), or on to the problem the engine chose. Null when nothing is
  /// saved or the pack no longer has that problem. A case whose session
  /// ended (time up, or the server ended it) is [WhereNext.carryFrom]: it
  /// carries on in a new session, its board rebuilt (SES-01, SES-04).
  Future<WhereNext?> whereNext(Pack pack, {String? childId}) async {
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
        if (open.closed) await _db.markEnded(open.events.first.sessionId);
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
    // left for another day (SES-06): a new case now; the server offers the
    // left one back later
    if (events.any((e) => e.name == 'problem_left')) {
      final next = problem.next.fast;
      return pack.problems.containsKey(next)
          ? (
              problemId: next,
              resumeSessionId: null,
              startedOn: null,
              carryFrom: null,
            )
          : null;
    }
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
              ? (
                  problemId: next,
                  resumeSessionId: null,
                  startedOn: null,
                  carryFrom: null,
                )
              : null;
        }
      }
    }
    // ended (time up, or by the server): a new session carries the case
    // on, its board rebuilt from these events; nothing begun, it starts
    // again from its question
    if (await _db.isEnded(sessionId) ||
        events.any((e) => e.name == 'session_ended')) {
      final begun = inputsFrom(pack, problem, events).length > 1;
      return (
        problemId: problem.id,
        resumeSessionId: null,
        startedOn: null,
        carryFrom: begun ? sessionId : null,
      );
    }
    return (
      problemId: problem.id,
      resumeSessionId: sessionId,
      startedOn: elsewhere?.sessionId == sessionId ? elsewhere?.label : null,
      carryFrom: null,
    );
  }

  void dispose() {
    _retry?.cancel();
    online.dispose();
    ended.dispose();
    lastStop.dispose();
  }

  static List<(String, List<LessonEvent>)> _bySession(List<LessonEvent> batch) {
    final groups = <String, List<LessonEvent>>{};
    for (final e in batch) {
      (groups[e.sessionId] ??= []).add(e);
    }
    return [for (final g in groups.entries) (g.key, g.value)];
  }
}
