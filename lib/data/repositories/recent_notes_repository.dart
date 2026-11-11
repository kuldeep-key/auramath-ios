import '../services/api.dart';
import '../services/api_client.dart';
import 'grown_up_repository.dart';

/// One session's note for the grown-up: when, and its sentences in the
/// server's order.
class SessionNote {
  const SessionNote({
    required this.sessionId,
    required this.at,
    required this.sentences,
  });

  final String sessionId;
  final DateTime? at;
  final List<String> sentences;

  /// Read loosely: `sessionId` (or `session_id`, `id`); `endedAt` (or `at`,
  /// `startedAt`) in ms or ISO 8601; `sentences` as `[{text}]` or strings,
  /// else one `text` or `summary`. Null when it has no id or no words.
  static SessionNote? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['sessionId'] ?? j['session_id'] ?? j['id'];
    if (id is! String) return null;
    final raw = j['sentences'];
    final sentences = <String>[
      if (raw is List)
        for (final s in raw)
          if (s is String)
            s
          else if (s is Map && s['text'] is String)
            s['text'],
      if (raw is! List)
        if ((j['text'] ?? j['summary']) case final String t) t,
    ].where((s) => s.trim().isNotEmpty).toList();
    if (sentences.isEmpty) return null;
    return SessionNote(
      sessionId: id,
      at: _time(j['endedAt'] ?? j['at'] ?? j['startedAt']),
      sentences: sentences,
    );
  }

  static DateTime? _time(Object? v) => switch (v) {
    final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
    final String s => DateTime.tryParse(s)?.toLocal(),
    _ => null,
  };
}

/// The last few session notes for a child (PAR-12), behind the
/// `recent_notes_in_app` flag.
///
/// Asks `GET /api/family/notes?childId={id}&limit=5` (the backend's
/// PAR-12 route): `{"notes": [{sessionId, childId, childName, startedAt,
/// endedAt, sentences: [{part, text, eventIds, claimIds}], delivery}]}`,
/// newest first, finished lessons only. An older server without that
/// route (404) is answered from the progress list, then each session's
/// summary.
class RecentNotesRepository {
  RecentNotesRepository(this._client, this._grownUps);

  final ApiClient _client;
  final GrownUpRepository _grownUps;

  static const limit = 5;

  Future<List<SessionNote>> recent(String childId) async {
    try {
      final j = await _client.get(
        '/api/family/notes',
        query: {'childId': childId, 'limit': '$limit'},
      );
      final list = j is Map ? (j['notes'] ?? j['items']) : j;
      return [
        for (final n in (list is List ? list : const []))
          ?SessionNote.fromJson(n),
      ].take(limit).toList();
    } on ApiException catch (e) {
      if (e.status != 404) rethrow;
    }
    // no last-five route yet: newest lessons first, those with a note
    final out = <SessionNote>[];
    for (final lesson in await _grownUps.lessons(childId)) {
      if (out.length == limit) break;
      if (lesson.endedAt == null) continue;
      final sentences = await _grownUps.summary(lesson.id);
      if (sentences.isEmpty) continue;
      out.add(
        SessionNote(
          sessionId: lesson.id,
          at: lesson.endedAt,
          sentences: sentences,
        ),
      );
    }
    return out;
  }
}
