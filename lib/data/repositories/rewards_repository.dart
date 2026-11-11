import 'package:flutter/foundation.dart';

import '../services/api.dart';
import '../services/api_client.dart';

/// A badge the server named (REW-01 session badge, REW-06 level badge).
typedef ServedBadge = ({String id, String name, String? says});

/// A stop on the trail as the server serves it (REW-04): its id, the
/// child-facing name from content, and the skill it stands for.
typedef ServedStop = ({String id, String name, String? skillId});

/// Where the child is on the trail, as the server knows it on every phone.
typedef ServedTrail = ({List<ServedStop> stops, int here, bool atTop});

/// The rewards the server decides (D-47, each behind the flag it serves),
/// from one route, `GET /api/children/{childId}/rewards` (the child's
/// phone or a grown-up's):
///
/// ```
/// {"sessionBadges": [{badgeId, kind: session, name, for, draftName,
///                     sessionId, awardedAt}] | null,      REW-01
///  "trail": {"questionTypes": [{templateId, skill, stops: [{stopId,
///            level, name, state: passed|here|next|mist}]}],
///            "draftNames"} | null,                         REW-04
///  "streak": {show, band, coveredMissedDay} | null,        REW-05
///  "levelBadges": [{badgeId, kind: skill_mastered, name, questionType,
///                   level, sessionId, draftName}] | null,  REW-06
///  "draft": bool}
/// ```
///
/// A part is null while its flag is off on the server. A server without
/// the route (404), or any failure, is "nothing served": the child's
/// screen then uses what this phone knows, and never shows an error for
/// a reward.
class RewardsRepository {
  RewardsRepository(this._client);

  final ApiClient _client;

  /// The comparison question type's id on the trail (its template id).
  static const comparisonType = 'cmp.comparison';

  Future<Map<Object?, Object?>?> _rewards(String childId) async {
    final path = '/api/children/$childId/rewards';
    try {
      final j = await _client.get(path);
      return j is Map ? j : null;
    } on ApiException catch (e) {
      if (e.status != 404) debugPrint('rewards: $path: $e');
      return null;
    }
  }

  /// REW-01: the one badge this session earned, whatever way it ended:
  /// the entry of `sessionBadges` for [sessionId]. Null until the server
  /// has the session's log (the phone then shows its own draft name).
  Future<ServedBadge?> sessionBadge(String sessionId, {String? childId}) async {
    if (childId == null) return null;
    final list = (await _rewards(childId))?['sessionBadges'];
    return badgeFrom(
      list is List
          ? list
                .whereType<Map>()
                .where((b) => b['sessionId'] == sessionId)
                .firstOrNull
          : null,
    );
  }

  /// REW-04: the comparison question type's stops. Null with none.
  Future<ServedTrail?> trail(String childId) async =>
      trailFrom((await _rewards(childId))?['trail']);

  /// REW-05: whether today's kind streak moment shows (`streak.show`).
  /// Never a number: days and the free missed days are the server's, in
  /// the family's time zone.
  Future<bool> streakMoment(String childId) async {
    final j = (await _rewards(childId))?['streak'];
    return j is Map && j['show'] == true;
  }

  /// REW-06: the level badges earned, first earned first (`levelBadges`,
  /// kind `skill_mastered`). Only earned badges are served.
  Future<List<ServedBadge>> levelBadges(String childId) async {
    final list = (await _rewards(childId))?['levelBadges'];
    return [
      if (list is List)
        for (final b in list)
          if (b is Map &&
              const {'skill_mastered', 'level'}.contains(b['kind'] ?? 'level'))
            ?badgeFrom(b),
    ];
  }

  static ServedBadge? badgeFrom(Object? j) {
    if (j is! Map) return null;
    final id = j['id'] ?? j['badgeId'] ?? j['badge_id'];
    final name = j['name'] ?? j['title'];
    if (id is! String || name is! String || name.trim().isEmpty) return null;
    final says = j['says'] ?? j['description'];
    return (id: id, name: name, says: says is String ? says : null);
  }

  /// The server's `trail` (`questionTypes`, REW-04): the comparison
  /// type's stops, else the first type's. Where the child is: the stop
  /// marked `here`; every stop `passed` is the top. Null with no stops.
  static ServedTrail? trailFrom(Object? j) {
    if (j is! Map || j['questionTypes'] is! List) return null;
    final types = (j['questionTypes'] as List).whereType<Map>().toList();
    final type =
        types.where((t) => t['templateId'] == comparisonType).firstOrNull ??
        types.firstOrNull;
    final raw = type?['stops'];
    if (raw is! List) return null;
    final skill = type!['skill'];
    final stops = <ServedStop>[];
    final states = <Object?>[];
    for (final s in raw) {
      if (s is Map && s['stopId'] is String && s['name'] is String) {
        stops.add((
          id: s['stopId'] as String,
          name: s['name'] as String,
          skillId: skill is String ? skill : null,
        ));
        states.add(s['state']);
      }
    }
    if (stops.isEmpty) return null;
    final atTop = states.every((s) => s == 'passed');
    final here = states.indexOf('here');
    return (
      stops: stops,
      here: here >= 0 ? here : (atTop ? stops.length - 1 : 0),
      atTop: atTop,
    );
  }
}
