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
  Future<({String sessionId, String childRef, String? checkLevel})>
  startSession({String? childId, required bool isDemo}) async {
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
    );
  }

  String childRef = 'ch_test1234';

  /// A spaced check due at this level, as the next session says.
  String? checkLevel;

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
