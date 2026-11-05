import '../models/lesson_event.dart';

/// A call to the backend failed: offline, timed out, or a non-2xx answer.
class ApiException implements Exception {
  const ApiException(this.message, {this.status});

  final String message;

  /// The HTTP status, or null when the server couldn't be reached.
  final int? status;

  bool get offline => status == null;

  @override
  String toString() => 'ApiException(${status ?? 'offline'}): $message';
}

/// The server's answer to a batch of events.
typedef EventsReply = ({
  /// Each refused event as "name: reasons". Those aren't stored; the rest
  /// of the batch is.
  List<String> rejected,

  /// Why the server ended the session, if it has: `paused` (offline 10+
  /// min), `idle` (30 min), or `full` (the log's 10,000 events, its 413).
  String? ended,
});

/// The child's unfinished lesson on the server.
typedef OpenCase = ({
  List<LessonEvent> events,
  bool sameDevice,
  String? startedOn,

  /// The server already ended it (`resume.closed`): a new session starts.
  bool closed,
});

/// A session the server just opened.
typedef StartedSession = ({
  String sessionId,
  String childRef,

  /// A spaced check is due at this level.
  String? checkLevel,

  /// A re-test of the skill is due (since this time, epoch ms): the first
  /// problem is a check at the child's level (SKL-06, `retestDue`).
  int? retestDueAt,

  /// The child hasn't done the starting check yet (SKL-07): the four sums
  /// come before the first case.
  bool startingCheckDue,

  /// A problem the child left last time, to offer back: `{id, problemId,
  /// problem, stepId, leftAt, ...}`, `problem` as it was shown.
  Map<String, Object?>? leftProblem,
});

/// The lesson's calls to the backend. Throws [ApiException] on any failure.
abstract interface class Api {
  /// `POST /api/sessions`: the server makes the session (online-first) and
  /// says which `child_ref` its events must carry, and the level of a
  /// spaced check that is due (its first problem is at that level).
  Future<StartedSession> startSession({String? childId, required bool isDemo});

  /// `POST /api/sessions/{id}/problems/next`: the next problem at the
  /// child's level (the server's memory), or at [level] ("something
  /// easier", a spaced check). 409 once the lesson has ended.
  Future<Map<String, Object?>> nextProblem(String sessionId, {String? level});

  /// `GET /api/sessions/resumable`: the child's unfinished lesson on the
  /// server, if any, with its events and where it was started (DEV-05).
  Future<OpenCase?> resumable({String? childId});

  /// `POST /api/sessions/{sessionId}/events` with `{"events": [...]}`.
  Future<EventsReply> sendEvents(String sessionId, List<LessonEvent> events);

  /// `POST /api/sessions/{id}/decisions`: the server's choice at a decision
  /// point, always one of [body]'s `allowed`; `{action, source, ...}`.
  Future<Map<String, Object?>> decide(
    String sessionId,
    Map<String, Object?> body,
  );

  /// `POST /api/children/{id}/arithmetic`: sums for [purpose]
  /// (`side_lesson`: smaller ones of the kind just practised;
  /// `starting_check`: the four for the child's age), each
  /// `{level, skill, op, a, b, answer, text}`.
  Future<List<Map<String, Object?>>> arithmetic(
    String childId, {
    required String purpose,
  });

  /// `POST /api/children/{id}/starting-check {correct}`: how many of the
  /// four starting sums were right. The server sets the child's level from
  /// its placement table and returns it (once; a second result changes
  /// nothing).
  Future<String> startingCheck(String childId, {required int correct});
}
