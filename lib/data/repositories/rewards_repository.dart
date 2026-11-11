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

/// The rewards the server decides (D-47, each behind the flag it serves).
/// Every call is here, the shapes read loosely, because the backend's
/// routes are not final. A route that isn't there yet (404), or any
/// failure, is "nothing served": the child's screen then uses what this
/// phone knows, and never shows an error for a reward.
///
/// Assumed routes (a parent's or the child's own phone may call them):
/// * `GET /api/sessions/{sessionId}/badge`   REW-01
/// * `GET /api/children/{childId}/trail`     REW-04
/// * `GET /api/children/{childId}/streak`    REW-05
/// * `GET /api/children/{childId}/badges`    REW-06 (`kind: level`)
class RewardsRepository {
  RewardsRepository(this._client);

  final ApiClient _client;

  Future<Object?> _get(String path) async {
    try {
      return await _client.get(path);
    } on ApiException catch (e) {
      if (e.status != 404) debugPrint('rewards: $path: $e');
      return null;
    }
  }

  /// REW-01: the one badge this session earned, whatever way it ended.
  /// `{"badge": {"id", "name"|"title", "says"?}}` or the badge itself.
  Future<ServedBadge?> sessionBadge(String sessionId) async {
    final j = await _get('/api/sessions/$sessionId/badge');
    return badgeFrom(j is Map && j['badge'] is Map ? j['badge'] : j);
  }

  /// REW-04: `{"stops": [{"id", "name", "skillId"?}], "here": <stop id or
  /// index>, "atTop"?: bool}`. Null with no stops.
  Future<ServedTrail?> trail(String childId) async =>
      trailFrom(await _get('/api/children/$childId/trail'));

  /// REW-05: whether today's kind streak moment shows. Never a number:
  /// `{"show": bool}` (or `moment`, `streakMoment`). Days and the free
  /// missed days are the server's, in the family's time zone.
  Future<bool> streakMoment(String childId) async {
    final j = await _get('/api/children/$childId/streak');
    if (j is! Map) return false;
    return (j['show'] ?? j['moment'] ?? j['streakMoment']) == true;
  }

  /// REW-06: the level badges earned, first earned first. `{"badges":
  /// [...]}` or a list; a badge with another `kind` than `level` is left
  /// out. Only earned badges are served.
  Future<List<ServedBadge>> levelBadges(String childId) async {
    final j = await _get('/api/children/$childId/badges');
    final list = j is Map ? j['badges'] : j;
    return [
      if (list is List)
        for (final b in list)
          if (b is Map && (b['kind'] ?? 'level') == 'level') ?badgeFrom(b),
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

  static ServedTrail? trailFrom(Object? j) {
    if (j is! Map || j['stops'] is! List) return null;
    final stops = <ServedStop>[
      for (final s in j['stops'] as List)
        if (s is Map && s['id'] is String && s['name'] is String)
          (
            id: s['id'] as String,
            name: s['name'] as String,
            skillId: (s['skillId'] ?? s['skill_id']) as String?,
          ),
    ];
    if (stops.isEmpty) return null;
    final h = j['here'] ?? j['current'];
    final here = h is int
        ? h.clamp(0, stops.length - 1)
        : stops.indexWhere((s) => s.id == h).clamp(0, stops.length - 1);
    return (
      stops: stops,
      here: here,
      atTop: j['atTop'] == true || j['at_top'] == true,
    );
  }
}
