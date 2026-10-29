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

/// The lesson's calls to the backend. Throws [ApiException] on any failure.
abstract interface class Api {
  /// `POST /api/sessions`: the server makes the session (online-first) and
  /// says which `child_ref` its events must carry.
  Future<({String sessionId, String childRef})> startSession({
    String? childId,
    required bool isDemo,
  });

  /// `POST /api/sessions/{sessionId}/events` with `{"events": [...]}`.
  Future<void> sendEvents(String sessionId, List<LessonEvent> events);
}
