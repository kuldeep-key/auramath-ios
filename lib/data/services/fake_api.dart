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
  Future<({String sessionId, String childRef})> startSession({
    String? childId,
    required bool isDemo,
  }) async {
    if (failNext > 0) {
      failNext--;
      throw const ApiException('offline');
    }
    final id = 's${sessions.length + 1}';
    sessions.add(id);
    return (sessionId: id, childRef: childRef);
  }

  String childRef = 'ch_test1234';

  /// What `resumable` answers; null = no unfinished case on the server.
  ({List<LessonEvent> events, bool sameDevice, String? startedOn})? openCase;

  @override
  Future<({List<LessonEvent> events, bool sameDevice, String? startedOn})?>
  resumable({String? childId}) async {
    if (failNext > 0) {
      failNext--;
      throw const ApiException('offline');
    }
    return openCase;
  }

  @override
  Future<void> sendEvents(String sessionId, List<LessonEvent> events) async {
    if (failNext > 0) {
      failNext--;
      throw const ApiException('offline');
    }
    batches.add((sessionId, events));
    for (final e in events) {
      if (_seen.add((sessionId, e.seq))) received.add(e);
    }
  }
}
