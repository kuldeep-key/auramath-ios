import '../models/lesson_event.dart';
import 'api.dart';

/// Stands in for the backend until it is ready, and in tests. Ignores a
/// repeated (sessionId, seq) the way the server does.
class FakeApi implements Api {
  /// How many calls fail before the next one succeeds.
  int failNext = 0;

  /// The starting check's calls answer this server error instead (a 5xx or
  /// 429: not offline).
  ApiException? startingRefused;

  final List<LessonEvent> received = [];
  final List<(String, List<LessonEvent>)> batches = [];
  final Set<(String, int)> _seen = {};

  final List<String> sessions = [];

  @override
  Future<StartedSession> startSession({
    String? childId,
    required bool isDemo,
  }) async {
    if (failNext > 0) {
      failNext--;
      throw const ApiException('offline');
    }
    final id = 's${sessions.length + 1}';
    sessions.add(id);
    // the server names the child as childRefFor does
    return (
      sessionId: id,
      childRef: childId == null ? childRef : childRefFor(childId),
      checkLevel: checkLevel,
      retestDueAt: retestDueAt,
      startingCheckDue: startingCheckDue,
      leftProblem: leftProblem,
      reviewDue: reviewDue,
      sittingId: sittingId ?? id,
      todaySuggestion: todaySuggestion,
    );
  }

  /// LES-14: the selector's suggestion, as every session says.
  TodaySuggestion? todaySuggestion;

  /// TUT-08's review queue, as every session says.
  List<Map<String, Object?>> reviewDue = const [];

  /// The sitting every session belongs to; null: its own.
  String? sittingId;

  String childRef = 'ch_test1234';

  /// A spaced check due at this level, as the next session says.
  String? checkLevel;

  /// A re-test due since this time, as the next session says.
  int? retestDueAt;

  /// The starting check is still to do, as every session says until its
  /// result is in.
  bool startingCheckDue = false;

  /// A problem the child left, as the next session offers it back.
  Map<String, Object?>? leftProblem;

  /// What `problems/next` hands out, in turn; each ask is kept in [asked].
  final List<Map<String, Object?>> problems = [];
  final List<(String, String?)> asked = [];

  /// The sessions whose ask said `easier: true`, in order.
  final List<String> askedEasier = [];

  @override
  Future<Map<String, Object?>> nextProblem(
    String sessionId, {
    String? level,
    bool easier = false,
    String? templateId,
  }) async {
    if (failNext > 0) {
      failNext--;
      throw const ApiException('offline');
    }
    asked.add((sessionId, level));
    if (easier) askedEasier.add(sessionId);
    if (problems.isEmpty) throw const ApiException('no problem', status: 409);
    return problems.removeAt(0);
  }

  /// Every decision asked for; the server's rules answer with the app's
  /// own default, as dev does while the AI is off, unless [decideWith]
  /// answers instead (late, failing, or the evaluator's own choice).
  final List<(String, Map<String, Object?>)> decisions = [];
  Future<Map<String, Object?>> Function(Map<String, Object?> body)? decideWith;

  @override
  Future<Map<String, Object?>> decide(
    String sessionId,
    Map<String, Object?> body,
  ) async {
    decisions.add((sessionId, body));
    if (decideWith case final answer?) return answer(body);
    return {
      'action': body['rulesDefault'],
      'source': 'rules',
      'cueAfterMs': 1000,
      'fallbackAfterMs': 4000,
    };
  }

  /// What `/arithmetic` hands out (the starting check's own in
  /// [startingSums]); empty: the server can't (404).
  final List<Map<String, Object?>> sums = [];
  final List<Map<String, Object?>> startingSums = [];

  /// The `level` each `/arithmetic` call asked for, in order.
  final List<String?> sumLevels = [];

  @override
  Future<List<Map<String, Object?>>> arithmetic(
    String childId, {
    required String purpose,
    String? level,
  }) async {
    sumLevels.add(level);
    final out = purpose == 'starting_check' ? startingSums : sums;
    if (out.isEmpty) throw const ApiException('no route', status: 404);
    return out;
  }

  /// Each starting check result sent, as `(childId, correct)`.
  final List<(String, int)> startingChecks = [];

  /// The level the server places the child at after the starting check.
  String placedAt = 'L3';

  @override
  Future<String> startingCheck(String childId, {required int correct}) async {
    if (failNext > 0) {
      failNext--;
      throw const ApiException('offline');
    }
    if (startingRefused case final e?) throw e;
    startingChecks.add((childId, correct));
    startingCheckDue = false;
    return placedAt;
  }

  /// What `resumable` answers; null = no unfinished case on the server.
  OpenCase? openCase;

  @override
  Future<OpenCase?> resumable({String? childId}) async {
    if (failNext > 0) {
      failNext--;
      throw const ApiException('offline');
    }
    return openCase;
  }

  /// Event names the server refuses (the rest of a batch is stored).
  final Set<String> refuse = {};

  /// Sessions the server has ended, and why.
  final Map<String, String> ended = {};

  /// SES-01: sessions ended with `session_ended {time_up}`, at that seq;
  /// a later seq posted there goes to a continuation, as the server does.
  final Map<String, int> timeUpAt = {};

  /// Each continuation opened (`c-<id>`), by the session it carries on.
  final Map<String, String> continuations = {};

  /// False: a server older than SES-01's continuations, which stores work
  /// after a time_up end in the ended session.
  bool continues = true;

  /// The badge the batch that ends a session answers with (REW-01).
  ServerBadge? badge;

  @override
  Future<EventsReply> sendEvents(
    String sessionId,
    List<LessonEvent> events,
  ) async {
    if (failNext > 0) {
      failNext--;
      throw const ApiException('offline');
    }
    batches.add((sessionId, events));
    String? continued;
    var ends = false;
    for (final e in events) {
      final end = timeUpAt[sessionId];
      final into = continues && end != null && e.seq > end
          ? continued = continuations[sessionId] ??= 'c-$sessionId'
          : sessionId;
      if (!refuse.contains(e.name) && _seen.add((into, e.seq))) {
        received.add(e);
        if (e.name == 'session_ended') {
          ends = true;
          if (e.payload['reason'] == 'time_up') timeUpAt[into] = e.seq;
        }
      }
    }
    return (
      rejected: [
        for (final e in events)
          if (refuse.contains(e.name)) '${e.name}: refused',
      ],
      ended: ended[sessionId],
      continuedIn: continued,
      badge: ends ? badge : null,
    );
  }
}
