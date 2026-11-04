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

/// The lesson's calls to the backend. Throws [ApiException] on any failure.
abstract interface class Api {
  /// `POST /api/sessions`: the server makes the session (online-first) and
  /// says which `child_ref` its events must carry.
  Future<({String sessionId, String childRef})> startSession({
    String? childId,
    required bool isDemo,
  });

  /// `GET /api/sessions/resumable`: the child's unfinished lesson on the
  /// server, if any, with its events and where it was started (DEV-05).
  Future<OpenCase?> resumable({String? childId});

  /// `POST /api/sessions/{sessionId}/events` with `{"events": [...]}`.
  Future<EventsReply> sendEvents(String sessionId, List<LessonEvent> events);
}
