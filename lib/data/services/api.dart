import '../models/lesson_event.dart';

/// A call to the backend failed: offline, timed out, or a non-2xx answer.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// The backend, as the app sees it. Throws [ApiException] on any failure.
abstract interface class Api {
  /// `POST /api/sessions/{sessionId}/events` with `{"events": [...]}`.
  Future<void> sendEvents(String sessionId, List<LessonEvent> events);
}
