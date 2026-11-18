import '../services/api.dart';
export '../services/api.dart' show ServerBadge;
import '../services/api_client.dart';

/// A case's story sticker (REW-15, catalogue `story_stickers`): one per
/// story object ("lemon tree"); two stories with one object share it.
typedef CaseSticker = ({String stickerId, String object});

/// One solved case in the casebook (`CasebookCase`): [name] is the
/// problem's plain name (TUT-12), [solvedAt] the phone's clock, epoch ms.
typedef CasebookCase = ({
  String problemId,
  String sessionId,
  String? name,
  CaseSticker sticker,
  int solvedAt,
});

/// One day of the casebook, in the family's home time zone: that day's
/// session badges and its solved cases, in the order solved. Never a count.
typedef CasebookDay = ({
  DateTime date,
  List<ServerBadge> sessionBadges,
  List<CasebookCase> cases,
});

/// A piece on the case's final board: `difference`, `total`, `label_a` or
/// `label_b`, where it was last committed (`bar_a`, `bar_b`, `gap`,
/// `across_both`, `board`), and its number when it carried one.
typedef DrawnPiece = ({String object, String target, int? value});

/// The case's final drawing, rebuilt by the server from its
/// `object_placed` events: the bars in grid units and every piece. Only
/// shapes and numbers, no story text.
typedef CaseDrawing = ({double barA, double barB, List<DrawnPiece> pieces});

/// A big badge (stop, land or habit) earned in the case (REW-12).
typedef CaseBadge = ({String badgeId, String kind, String name});

/// One case opened from the day view or a badge (REW-12): its drawing
/// (null when solved with nothing placed), its session's badge and the big
/// badges earned in it.
typedef CaseView = ({
  CasebookCase entry,
  DateTime date,
  CaseDrawing? drawing,
  ServerBadge? sessionBadge,
  List<CaseBadge> badges,
});

/// REW-15: the child's casebook, from the server (behind `flags.casebook`):
///
/// ```
/// GET /api/children/{childId}/casebook
///   {"world", "days": [{"date", "sessionBadges": [Badge],
///                       "cases": [CasebookCase]}] | null}
/// GET /api/children/{childId}/casebook/cases/{problemId}
///   {...CasebookCase, "date", "drawing": {"barA", "barB",
///    "pieces": [{"object", "target", "value"}]} | null,
///    "sessionBadge": Badge | null, "badges": [{"badgeId", "kind", "name"}]}
/// ```
///
/// Unlike a reward, a failed read is the child's to see (ErrChild, retry):
/// the casebook is a screen of its own, not a part of one.
class CasebookRepository {
  CasebookRepository(this._client);

  final ApiClient _client;

  /// The days, newest first; null while the server's casebook is off.
  /// Throws [ApiException] when offline or refused.
  Future<({String world, List<CasebookDay>? days})> days(String childId) async {
    final j = await _client.get('/api/children/$childId/casebook');
    return daysFrom(j);
  }

  /// One case; null when the server has no such case for this child, or
  /// its casebook is off (404). Throws [ApiException] otherwise.
  Future<CaseView?> caseOf(String childId, String problemId) async {
    try {
      final j = await _client.get(
        '/api/children/$childId/casebook/cases/${Uri.encodeComponent(problemId)}',
      );
      return caseFrom(j);
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  static ({String world, List<CasebookDay>? days}) daysFrom(Object? j) {
    final map = j is Map ? j : const {};
    final world = map['world'] as String? ?? 'detective';
    final raw = map['days'];
    if (raw is! List) return (world: world, days: null);
    return (
      world: world,
      days: [
        for (final d in raw.whereType<Map>())
          if (DateTime.tryParse('${d['date']}') case final date?)
            (
              date: date,
              sessionBadges: [
                for (final b in d['sessionBadges'] as List? ?? const [])
                  ?badgeFromJson(b),
              ],
              cases: [
                for (final c in d['cases'] as List? ?? const []) ?entryFrom(c),
              ],
            ),
      ],
    );
  }

  static CasebookCase? entryFrom(Object? j) {
    if (j is! Map || j['problemId'] is! String) return null;
    final s = j['sticker'];
    final object = s is Map && s['object'] is String
        ? s['object'] as String
        : 'story';
    return (
      problemId: j['problemId'] as String,
      sessionId: j['sessionId'] as String? ?? '',
      name: j['name'] as String?,
      sticker: (
        stickerId: s is Map && s['stickerId'] is String
            ? s['stickerId'] as String
            : 'sticker.story',
        object: object,
      ),
      solvedAt: (j['solvedAt'] as num?)?.toInt() ?? 0,
    );
  }

  static CaseView? caseFrom(Object? j) {
    final entry = entryFrom(j);
    if (entry == null || j is! Map) return null;
    final d = j['drawing'];
    return (
      entry: entry,
      date:
          DateTime.tryParse('${j['date']}') ??
          DateTime.fromMillisecondsSinceEpoch(entry.solvedAt),
      drawing: d is Map && d['barA'] is num && d['barB'] is num
          ? (
              barA: (d['barA'] as num).toDouble(),
              barB: (d['barB'] as num).toDouble(),
              pieces: [
                for (final p
                    in (d['pieces'] as List? ?? const []).whereType<Map>())
                  if (p['object'] is String)
                    (
                      object: p['object'] as String,
                      target: '${p['target']}',
                      value: (p['value'] as num?)?.toInt(),
                    ),
              ],
            )
          : null,
      sessionBadge: badgeFromJson(j['sessionBadge']),
      badges: [
        for (final b in (j['badges'] as List? ?? const []).whereType<Map>())
          if (b['badgeId'] is String && b['name'] is String)
            (
              badgeId: b['badgeId'] as String,
              kind: b['kind'] as String? ?? 'skill_mastered',
              name: b['name'] as String,
            ),
      ],
    );
  }
}
