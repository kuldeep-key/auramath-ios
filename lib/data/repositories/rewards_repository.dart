import 'package:flutter/foundation.dart';

import '../services/api.dart';
export '../services/api.dart' show Award, ServerBadge;
import '../services/api_client.dart';

/// A badge the server named (REW-01 session badge, REW-06 level badge).
typedef ServedBadge = ({String id, String name, String? says});

/// A stop on the trail as the server serves it (REW-04): its id, the
/// child-facing name from content, and the skill it stands for.
typedef ServedStop = ({String id, String name, String? skillId});

/// REW-05: today's kind streak moment, as the server decides it: its band
/// of days (`2`, `3_to_6`, `7_plus`, never shown as a number) and whether a
/// free missed day kept it going. Logged as `streak_moment_shown`.
typedef StreakMoment = ({String band, bool coveredMissedDay});

/// Where the child is on the trail, as the server knows it on every phone.
typedef ServedTrail = ({List<ServedStop> stops, int here, bool atTop});

/// A badge in the cabinet (REW-12): earned only, never an outline. Its
/// name is the child's world's; [problemId] the case it came from.
typedef CabinetBadge = ({
  String badgeId,
  String kind,
  String name,
  String? problemId,
  bool polishMe,
});

/// A stop on the path (JRN-03, journey spec 5.3): `earned`, `explored`,
/// `current`, `next` or `mist`, and Polish me (REW-08).
typedef PathStop = ({String stopId, String name, String state, bool polishMe});

/// A land on the path: the one the child is in ([current], every stop),
/// or the one teaser of the next ([teaser], no stops). [stopInLevel] (0 to
/// 3, the current land's `stopInLevel`) is how many of the four stops
/// before the current level's peak the child has walked, as the server's
/// move-up gate decides (never a count of cases); 0 when it is absent.
typedef PathLand = ({
  String landId,
  String name,
  bool current,
  bool teaser,
  int stopInLevel,
  List<PathStop> stops,
});

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

  /// The whole rewards answer, read once, for a screen that needs more
  /// than one part of it (Home's badge and streak, FL-49).
  Future<Rewards> read(String childId) async =>
      Rewards(await _rewards(childId));

  /// REW-01: the one badge this session earned, whatever way it ended:
  /// the entry of `sessionBadges` for [sessionId]. Null until the server
  /// has the session's log (the phone then shows its own draft name).
  Future<ServedBadge?> sessionBadge(String sessionId, {String? childId}) async {
    if (childId == null) return null;
    return (await read(childId)).sessionBadge(sessionId);
  }

  /// REW-04: the comparison question type's stops. Null with none.
  Future<ServedTrail?> trail(String childId) async =>
      trailFrom((await _rewards(childId))?['trail']);

  /// REW-05: whether today's kind streak moment shows (`streak.show`).
  /// Never a number: days and the free missed days are the server's, in
  /// the family's time zone.
  Future<bool> streakMoment(String childId) async =>
      await streak(childId) != null;

  /// REW-05: today's moment, with its band; null when it doesn't show.
  Future<StreakMoment?> streak(String childId) async =>
      (await read(childId)).streak;

  /// The server's `streak` when today's moment shows; null when it doesn't.
  static StreakMoment? streakFrom(Object? j) {
    if (j is! Map || j['show'] != true) return null;
    final band = j['band'];
    return (
      band: const {'2', '3_to_6', '7_plus'}.contains(band)
          ? band as String
          : '2',
      coveredMissedDay: j['coveredMissedDay'] == true,
    );
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

/// One `GET /api/children/{childId}/rewards` answer, read by part; empty
/// when nothing was served.
class Rewards {
  const Rewards(this._j);

  final Map<Object?, Object?>? _j;

  /// REW-01: the entry of `sessionBadges` for [sessionId].
  ServedBadge? sessionBadge(String sessionId) {
    final list = _j?['sessionBadges'];
    return RewardsRepository.badgeFrom(
      list is List
          ? list
                .whereType<Map>()
                .where((b) => b['sessionId'] == sessionId)
                .firstOrNull
          : null,
    );
  }

  /// REW-05: today's moment, or null.
  StreakMoment? get streak => RewardsRepository.streakFrom(_j?['streak']);

  /// The child's world (REW-17); Detective while `flags.worlds` is off.
  String get world => _j?['world'] as String? ?? 'detective';

  /// REW-01: a session badge not yet shown, from a session that ended by
  /// app_closed or offline_timeout: shown on the next open, before
  /// anything else. Its session, when the server names it.
  ({ServerBadge badge, String? sessionId})? get pendingSessionBadge {
    final j = _j?['pendingSessionBadge'];
    final b = badgeFromJson(j);
    if (b == null) return null;
    return (badge: b, sessionId: (j as Map)['sessionId'] as String?);
  }

  /// REW-11: big badges earned and waiting to show (on no phone yet),
  /// each [Award.queued]: it waited.
  List<Award> get queued => [
    for (final a in awardsFromJson(_j?['queued']))
      (
        badgeId: a.badgeId,
        kind: a.kind,
        name: a.name,
        problemId: a.problemId,
        celebration: a.celebration,
        queued: true,
        alsoLand: a.alsoLand,
      ),
  ];

  /// REW-12: the cabinet's badges, earned only; null while
  /// `flags.badge_cabinet` is off.
  List<CabinetBadge>? get cabinet {
    final list = _j?['cabinet'];
    if (list is! List) return null;
    return [
      for (final b in list.whereType<Map>())
        if (b['badgeId'] is String && b['name'] is String)
          (
            badgeId: b['badgeId'] as String,
            kind: b['kind'] as String? ?? 'skill_mastered',
            name: b['name'] as String,
            problemId: b['problemId'] as String?,
            polishMe: b['polishMe'] == true,
          ),
    ];
  }

  /// JRN-03: the path's lands (`trail.lands`): the current one in full,
  /// and one teaser; null while `flags.trail` is off, or from a server
  /// before v0.5.4 (`trail.questionTypes`, [RewardsRepository.trailFrom]).
  List<PathLand>? get lands {
    final trail = _j?['trail'];
    final raw = trail is Map ? trail['lands'] : null;
    if (raw is! List) return null;
    const states = {'earned', 'explored', 'current', 'next', 'mist'};
    return [
      for (final l in raw.whereType<Map>())
        if (l['landId'] is String)
          (
            landId: l['landId'] as String,
            name: l['name'] as String? ?? '',
            current: l['current'] == true,
            teaser: l['teaser'] == true,
            stopInLevel: switch (l['stopInLevel']) {
              final num n => n.toInt().clamp(0, 3),
              _ => 0,
            },
            stops: [
              for (final s
                  in (l['stops'] as List? ?? const []).whereType<Map>())
                if (s['stopId'] is String && s['name'] is String)
                  (
                    stopId: s['stopId'] as String,
                    name: s['name'] as String,
                    state: states.contains(s['state'])
                        ? s['state'] as String
                        : 'mist',
                    polishMe: s['polishMe'] == true,
                  ),
            ],
          ),
    ];
  }
}
