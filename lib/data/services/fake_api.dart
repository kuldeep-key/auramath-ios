import '../models/lesson_event.dart';
import 'api.dart';

/// Stands in for the backend until it is ready, and in tests. Ignores a
/// repeated (sessionId, seq) the way the server does.
class FakeApi implements Api {
  /// How many calls fail before the next one succeeds.
  int failNext = 0;

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
    );
  }

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

  @override
  Future<Map<String, Object?>> nextProblem(
    String sessionId, {
    String? level,
  }) async {
    if (failNext > 0) {
      failNext--;
      throw const ApiException('offline');
    }
    asked.add((sessionId, level));
    if (problems.isEmpty) throw const ApiException('no problem', status: 409);
    return problems.removeAt(0);
  }

  /// Every decision asked for; the server's rules answer with the app's
  /// own default, as dev does while the AI is off.
  final List<(String, Map<String, Object?>)> decisions = [];

  @override
  Future<Map<String, Object?>> decide(
    String sessionId,
    Map<String, Object?> body,
  ) async {
    decisions.add((sessionId, body));
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

  @override
  Future<List<Map<String, Object?>>> arithmetic(
    String childId, {
    required String purpose,
  }) async {
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
    for (final e in events) {
      if (!refuse.contains(e.name) && _seen.add((sessionId, e.seq))) {
        received.add(e);
      }
    }
    return (
      rejected: [
        for (final e in events)
          if (refuse.contains(e.name)) '${e.name}: refused',
      ],
      ended: ended[sessionId],
    );
  }
}
