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

/// A badge the server awarded (REW-01, D-47 draft names): `kind` session
/// or skill_mastered, `forWhat` (`solved`, `worked_on`, `opened`) for a
/// session's.
typedef ServerBadge = ({
  String badgeId,
  String kind,
  String name,
  String? forWhat,
  bool draftName,
});

/// A badge as the server sends it, or null when it isn't one.
ServerBadge? badgeFromJson(Object? j) {
  if (j is! Map || j['badgeId'] is! String || j['name'] is! String) {
    return null;
  }
  return (
    badgeId: j['badgeId'] as String,
    kind: j['kind'] as String? ?? 'session',
    name: j['name'] as String,
    forWhat: j['for'] as String?,
    draftName: j['draftName'] == true,
  );
}

/// The server's answer to a batch of events.
typedef EventsReply = ({
  /// Each refused event as "name: reasons". Those aren't stored; the rest
  /// of the batch is.
  List<String> rejected,

  /// Why the server ended the session, if it has: `paused` (offline 10+
  /// min), `idle` (30 min), or `full` (the log's 10,000 events, its 413).
  String? ended,

  /// SES-01: the batch came after the session's `session_ended {time_up}`,
  /// so the server stored it in this continuation session (`continuedIn`,
  /// resumedFrom the posted one): the rest of the lesson goes there.
  String? continuedIn,

  /// REW-01: the lesson's badge, in the answer to the batch that ends it.
  ServerBadge? badge,
});

/// The child's unfinished lesson on the server.
typedef OpenCase = ({
  List<LessonEvent> events,
  bool sameDevice,
  String? startedOn,

  /// The server already ended it (`resume.closed`): a new session starts.
  bool closed,

  /// Why it ended (`resume.closed.reason`): `paused`, `idle`, or `time_up`
  /// (the app ended it at the cap, SES-01: it carries on in a continuation).
  String? closedReason,

  /// SES-01 (`resume.carried`): the time_up sessions this one carries on,
  /// oldest first, each its events, so the whole board is rebuilt.
  List<List<LessonEvent>> carried,
});

/// LES-14: what the selector suggests for today, from the skill memory
/// (`todaySuggestion {skill, level, reason}`): an arithmetic skill
/// (`arith.*`, an `A` level) is Quick sums; anything else, the story
/// problem.
typedef TodaySuggestion = ({String skill, String level, String reason});

/// The server's [TodaySuggestion], or null when it sent none.
TodaySuggestion? todaySuggestionFromJson(Object? j) {
  if (j is! Map || j['skill'] is! String) return null;
  return (
    skill: j['skill'] as String,
    level: j['level'] as String? ?? '',
    reason: j['reason'] as String? ?? '',
  );
}

/// Quick sums is the suggestion (LES-14): an arithmetic skill or level.
bool suggestsQuickSums(TodaySuggestion? s) =>
    s != null &&
    (s.skill == 'quick_sums' ||
        s.skill.startsWith('arith.') ||
        RegExp(r'^A\d+$').hasMatch(s.level));

/// SES-07: the child is back on a later day than their last lesson, on
/// any phone, in the family's time zone (`welcomeBack`).
typedef WelcomeBack = ({int lastLessonAt, int daysAway, bool caseWaiting});

/// The server's [WelcomeBack], or null (the same day, a first lesson, or
/// a server that doesn't send it).
WelcomeBack? welcomeBackFromJson(Object? j) {
  if (j is! Map || j['daysAway'] is! int) return null;
  return (
    lastLessonAt: j['lastLessonAt'] as int? ?? 0,
    daysAway: j['daysAway'] as int,
    caseWaiting: j['caseWaiting'] == true,
  );
}

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

  /// TUT-08: skills to warm up on, each `{skill, errorType, reason}`
  /// (`over_limit`, `one_off`); a finished side lesson for the skill
  /// (`side_lesson_ended {skill_id, completed: true}`) clears it.
  List<Map<String, Object?>> reviewDue,

  /// The sitting this lesson belongs to (the id of its first session),
  /// informational (PAR-01: one note per sitting).
  String? sittingId,

  /// LES-14: the selector's suggestion for today; null from a server that
  /// sends none (then the story problem comes first, as before).
  TodaySuggestion? todaySuggestion,

  /// SES-07: back on a later day, as the server counts days; null on the
  /// same day, for a first lesson, or from an older server.
  WelcomeBack? welcomeBack,
});

/// The lesson's calls to the backend. Throws [ApiException] on any failure.
abstract interface class Api {
  /// `POST /api/sessions`: the server makes the session (online-first) and
  /// says which `child_ref` its events must carry, and the level of a
  /// spaced check that is due (its first problem is at that level).
  Future<StartedSession> startSession({String? childId, required bool isDemo});

  /// `POST /api/sessions/{id}/problems/next`: the next problem at the
  /// child's level (the server's memory), or at [level] (a spaced check,
  /// the starting check's placement); [easier] one level below that
  /// ("something easier", CON-06: served with `variant: easier`, which
  /// `problem_shown` echoes). [templateId] another question type
  /// (CON-07, behind its flag). 409 once the lesson has ended.
  Future<Map<String, Object?>> nextProblem(
    String sessionId, {
    String? level,
    bool easier = false,
    String? templateId,
  });

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
    String? level,
  });

  /// `POST /api/children/{id}/starting-check {correct}`: how many of the
  /// four starting sums were right. The server sets the child's level from
  /// its placement table and returns it (once; a second result changes
  /// nothing).
  Future<String> startingCheck(String childId, {required int correct});
}
