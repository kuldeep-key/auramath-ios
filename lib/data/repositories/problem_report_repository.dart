import '../services/api_client.dart';

/// One problem a child was shown in one of the last sessions, which a
/// report can name (`GET /api/family/problem-reports/choices`). Shown to
/// the parent or carer by the child, the day and the story, never its ids.
class ReportChoice {
  const ReportChoice({
    required this.sessionId,
    required this.childId,
    required this.startedAt,
    required this.problemId,
    required this.shownAt,
    this.contentVersion,
    this.title,
  });

  /// Null when [j] isn't one.
  static ReportChoice? fromJson(Object? j) {
    if (j is! Map ||
        j['sessionId'] is! String ||
        j['problemId'] is! String ||
        j['childId'] is! String) {
      return null;
    }
    DateTime at(Object? ms) =>
        DateTime.fromMillisecondsSinceEpoch(ms is int ? ms : 0);
    return ReportChoice(
      sessionId: j['sessionId'] as String,
      childId: j['childId'] as String,
      startedAt: at(j['startedAt']),
      problemId: j['problemId'] as String,
      shownAt: at(j['shownAt'] ?? j['startedAt']),
      contentVersion: j['contentVersion'] as String?,
      title: switch (j['title']) {
        final String t when t.trim().isNotEmpty => t.trim(),
        _ => null,
      },
    );
  }

  final String sessionId;
  final String childId;
  final DateTime startedAt;
  final String problemId;
  final DateTime shownAt;
  final String? contentVersion;

  /// The story's title from the server's problem bank ("The lemon tree and
  /// the fig tree"); null for a generated story the bank doesn't hold.
  final String? title;
}

/// PAR-13: "Report a problem" in the Family area, into Key's weekly review
/// (OPS-02). The parent's token only.
class ProblemReportRepository {
  ProblemReportRepository(this._client);

  final ApiClient _client;
  static const _path = '/api/family/problem-reports';

  /// The last sessions' problems, newest first; [childId] for one child's.
  Future<List<ReportChoice>> choices({String? childId}) async {
    final j =
        await _client.get('$_path/choices', query: {'childId': ?childId})
            as Map<String, Object?>;
    return [
      for (final c in j['choices'] as List? ?? const [])
        ?ReportChoice.fromJson(c),
    ];
  }

  /// Sends a report about [about], or "something else" when it is null,
  /// with the optional [note] (at most 500 characters; the server takes
  /// names out too). 201; 400, 403, 404 and 429 are [ApiException]s.
  Future<void> send({ReportChoice? about, String? note}) {
    final text = note?.trim() ?? '';
    return _client.post(_path, {
      'kind': about == null ? 'something_else' : 'problem',
      if (about != null) ...{
        'sessionId': about.sessionId,
        'problemId': about.problemId,
        'contentVersion': ?about.contentVersion,
      },
      if (text.isNotEmpty) 'note': text,
    });
  }

  /// The longest note the server keeps.
  static const noteMax = 500;
}
