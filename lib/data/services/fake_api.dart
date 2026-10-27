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
