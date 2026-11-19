import '../services/api.dart';
export '../services/api.dart' show ServerBadge;
import '../services/api_client.dart';

/// A case's story sticker (REW-15, catalogue `story_stickers`): one per
/// story object ("lemon tree"); two stories with one object share it.
/// [subject] is the story's kind of thing (`tree`, `building`, `animal`,
/// ...), else its quantity (`cost`, `length`), else `story`; null from an
/// older server. The app maps it to a picture.
typedef CaseSticker = ({String stickerId, String object, String? subject});

/// The case's story from the problem bank (`CasebookCase.story`): the two
/// things' names ([a], [b]), the kind, the unit and the quantity. Null for
/// a generated story, which has no names. Only the bank's words.
typedef CaseStory = ({
  String storyId,
  String? a,
  String? b,
  String kind,
  String? unit,
  String? quantity,
});

/// A number in the bar model: [given] in the story, else found by the
/// child.
typedef BarNumber = ({int value, bool given});

/// One bar of the case's model (`CasebookBar`): the thing's name from the
/// bank (null for a generated story) and its number.
typedef CaseBar = ({String? label, int value, bool given});

/// The case's bar model with its numbers (`CasebookCase.bars`): [barA] the
/// story's first thing, [barB] the second, [gap] the difference and
/// [acrossBoth] the two together (null at a one-step level).
typedef CaseBars = ({
  String relation,
  String? unit,
  CaseBar barA,
  CaseBar barB,
  BarNumber gap,
  BarNumber? acrossBoth,
});

/// One solved case in the casebook (`CasebookCase`): [name] is the
/// problem's plain name (TUT-12), [solvedAt] the phone's clock, epoch ms.
/// [story] and [bars] are null from an older server, [story] also for a
/// generated story and [bars] when the numbers are not in the log.
typedef CasebookCase = ({
  String problemId,
  String sessionId,
  String? name,
  CaseSticker sticker,
  int solvedAt,
  CaseStory? story,
  CaseBars? bars,
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
/// CasebookCase: {"problemId", "sessionId", "name", "solvedAt",
///   "sticker": {"stickerId", "object", "subject"},
///   "story": {"storyId", "a", "b", "kind", "unit", "quantity"} | null,
///   "bars": {"relation", "unit", "barA": {"label", "value", "given"},
///            "barB": {...}, "gap": {"value", "given"},
///            "acrossBoth": {"value", "given"} | null} | null}
/// GET /api/children/{childId}/casebook/cases/{problemId}
///   {...CasebookCase, "date", "drawing": {"barA", "barB",
///    "pieces": [{"object", "target", "value"}]} | null,
///    "bars": {"barA": {"value"}, "barB": {"value"}, ...} | null,
///    "sessionBadge": Badge | null, "badges": [{"badgeId", "kind", "name"}]}
/// ```
///
/// Unlike a reward, a failed read is the child's to see (ErrChild, retry):
/// the casebook is a screen of its own, not a part of one.
class CasebookRepository {
  CasebookRepository(this._client);

  final ApiClient _client;

  /// The days, newest first; null while the server's casebook is off, or
  /// the child is no longer the family's (a 404: deleted). Throws
  /// [ApiException] when offline or refused otherwise.
  Future<({String world, List<CasebookDay>? days})> days(String childId) async {
    try {
      return daysFrom(await _client.get('/api/children/$childId/casebook'));
    } on ApiException catch (e) {
      if (e.status == 404) return (world: 'detective', days: null);
      rethrow;
    }
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
        subject: s is Map && s['subject'] is String
            ? s['subject'] as String
            : null,
      ),
      solvedAt: (j['solvedAt'] as num?)?.toInt() ?? 0,
      story: storyFrom(j['story']),
      bars: barsFrom(j['bars']),
    );
  }

  static String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

  static CaseStory? storyFrom(Object? j) {
    if (j is! Map) return null;
    return (
      storyId: _str(j['storyId']) ?? '',
      a: _str(j['a']),
      b: _str(j['b']),
      kind: _str(j['kind']) ?? 'story',
      unit: _str(j['unit']),
      quantity: _str(j['quantity']),
    );
  }

  static BarNumber? _number(Object? j) => j is Map && j['value'] is num
      ? (value: (j['value'] as num).toInt(), given: j['given'] == true)
      : null;

  static CaseBar? _bar(Object? j) => switch (_number(j)) {
    final n? => (
      label: _str((j! as Map)['label']),
      value: n.value,
      given: n.given,
    ),
    null => null,
  };

  /// The bar model; null when it or any of its bars or the gap is missing.
  static CaseBars? barsFrom(Object? j) {
    if (j is! Map) return null;
    final (a, b, gap) = (_bar(j['barA']), _bar(j['barB']), _number(j['gap']));
    if (a == null || b == null || gap == null) return null;
    return (
      relation: _str(j['relation']) ?? 'more',
      unit: _str(j['unit']),
      barA: a,
      barB: b,
      gap: gap,
      acrossBoth: _number(j['acrossBoth']),
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
              pieces: _withBarNumbers([
                for (final p
                    in (d['pieces'] as List? ?? const []).whereType<Map>())
                  // a piece the child dropped off the board isn't drawn
                  if (p['object'] is String && p['target'] != 'none')
                    (
                      object: p['object'] as String,
                      target: '${p['target']}',
                      value: (p['value'] as num?)?.toInt(),
                    ),
              ], j['bars']),
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

  /// The numbers on the two bars, as on the lesson board: the lesson
  /// places no label piece for a number the story gives (A's) or one the
  /// child types (the unknown bar), so the drawing alone shows only the
  /// difference. The case's `bars` has both (given, or found by the
  /// child) and wins over a label piece, as on the case board's heads.
  static List<DrawnPiece> _withBarNumbers(
    List<DrawnPiece> pieces,
    Object? bars,
  ) {
    if (bars is! Map) return pieces;
    int? value(String bar) {
      final b = bars[bar];
      return b is Map ? (b['value'] as num?)?.toInt() : null;
    }

    final fromBars = <String, DrawnPiece>{
      for (final (label, bar, target) in const [
        ('label_a', 'barA', 'bar_a'),
        ('label_b', 'barB', 'bar_b'),
      ])
        if (value(bar) case final v?)
          label: (object: label, target: target, value: v),
    };
    return [
      for (final p in pieces)
        if (!fromBars.containsKey(p.object)) p,
      ...fromBars.values,
    ];
  }
}
