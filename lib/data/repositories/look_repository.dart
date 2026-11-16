import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/foundation.dart';

import '../models/journey_config.dart';
import '../services/api.dart';
import '../services/api_client.dart';

/// The steps of first run the server can say are still to do (JRN-01):
/// the rest (who's learning, Home) need no answer.
const firstRunSteps = ['world', 'look', 'tutor', 'meet'];

/// The child's look, tutor, voice and world (D-60, JRN-07), as the server
/// keeps them for every phone; and the first-run steps still to answer.
class ChildLook {
  const ChildLook({
    required this.childId,
    required this.world,
    required this.avatarId,
    required this.tutorId,
    required this.voiceId,
    this.needsFirstRun = const [],
    this.worldFromNextSession = false,
  });

  factory ChildLook.fromJson(
    Map<Object?, Object?> j,
    JourneyConfig config, {
    required String childId,
  }) {
    final tutor = j['tutorId'] is String
        ? j['tutorId'] as String
        : config.defaultTutor;
    return ChildLook(
      childId: j['childId'] as String? ?? childId,
      world: j['world'] as String? ?? config.defaultWorld,
      avatarId: lookIdFor(j['avatarId'] as String?),
      tutorId: tutor,
      voiceId: config.voiceFor(tutor, j['voiceId'] as String?),
      needsFirstRun: [
        for (final s in j['needsFirstRun'] as List? ?? const [])
          if (firstRunSteps.contains(s)) '$s',
      ],
      worldFromNextSession: j['worldFromNextSession'] == true,
    );
  }

  /// The look a child has before any is known: [config]'s defaults, and
  /// the avatar the family's list holds, if any.
  factory ChildLook.fallback(
    String childId,
    JourneyConfig config, {
    String? avatar,
  }) => ChildLook(
    childId: childId,
    world: config.defaultWorld,
    avatarId: lookIdFor(avatar),
    tutorId: config.defaultTutor,
    voiceId: config.voiceFor(config.defaultTutor),
  );

  final String childId;
  final String world;

  /// `look_01` to `look_08` (looks.yaml); never a gender.
  final String avatarId;
  final String tutorId;
  final String voiceId;

  /// `world`, `look`, `tutor`, `meet`: first run resumes at the first one
  /// (JRN-01). Empty once done.
  final List<String> needsFirstRun;

  /// True when a world change waits for the next session (REW-17).
  final bool worldFromNextSession;

  /// What `session_started.look` records (JRN-07).
  SessionLook get session =>
      (avatarId: avatarId, tutorId: tutorId, voiceId: voiceId, world: world);

  ChildLook copyWith({
    String? avatarId,
    String? tutorId,
    String? voiceId,
    String? world,
    List<String>? needsFirstRun,
  }) => ChildLook(
    childId: childId,
    world: world ?? this.world,
    avatarId: avatarId ?? this.avatarId,
    tutorId: tutorId ?? this.tutorId,
    voiceId: voiceId ?? this.voiceId,
    needsFirstRun: needsFirstRun ?? this.needsFirstRun,
    worldFromNextSession: worldFromNextSession,
  );
}

/// The six avatars before looks (ACC-12, v4.1), as the server maps them
/// to the first six looks.
const _oldAvatars = ['lens', 'print', 'key', 'map', 'idea', 'notes'];

/// The look for a stored avatar id: a look id as it is; one of the old six
/// as the server maps it; none known, the first look.
String lookIdFor(String? avatar) {
  if (avatar != null && RegExp(r'^look_0[1-8]$').hasMatch(avatar)) {
    return avatar;
  }
  final old = _oldAvatars.indexOf(avatar ?? '');
  return old < 0 ? 'look_01' : 'look_0${old + 1}';
}

/// The child's choices of who they are and who teaches them (D-60):
///
/// - `GET /api/children/{id}/look` →
///   `{childId, world, avatarId, tutorId, voiceId, needsFirstRun}`
/// - `PUT /api/children/{id}/look` with any of `{world, avatarId, tutorId,
///   voiceId}` (`surprise` for avatarId and tutorId: the server picks) →
///   the full look. 422 for an id not enabled.
/// - `POST /api/children/{id}/first-run` `{step}` marks a step done.
///
/// The last look read or saved is kept for the next lesson's
/// `session_started.look`, and for Home's first frame. A server without
/// the route (404) is a server before looks: the child gets the defaults
/// and no first run (nothing to resume on another phone).
class LookRepository extends ChangeNotifier {
  LookRepository(this._client, this.config);

  final ApiClient _client;
  final JourneyConfig config;

  final _looks = <String, ChildLook>{};

  /// The look last known for [childId]; null before any read.
  ChildLook? cached(String? childId) =>
      childId == null ? null : _looks[childId];

  /// The look a session records for [childId]: the last known, else the
  /// defaults.
  SessionLook sessionLook(String? childId, {String? avatar}) =>
      (cached(childId) ??
              ChildLook.fallback(childId ?? '', config, avatar: avatar))
          .session;

  /// Reads the child's look; offline or on an error, the last one known,
  /// else the defaults (with no first-run steps: they are asked when the
  /// server can say which are done).
  Future<ChildLook> read(String childId, {String? avatar}) async {
    try {
      final j = await _client.get('/api/children/$childId/look');
      if (j is Map) {
        return _keep(ChildLook.fromJson(j, config, childId: childId));
      }
    } on ApiException catch (e) {
      if (e.status != 404) debugPrint('look: $e');
    }
    return _looks[childId] ??
        ChildLook.fallback(childId, config, avatar: avatar);
  }

  /// Saves a choice (any of them; `surprise` for [avatarId] or [tutorId]).
  /// Switching tutor starts its own default voice (tutors.yaml
  /// `switching_tutor_resets_voice`); the server does the same. Throws
  /// when it can't be saved: the screen says so and stays.
  Future<ChildLook> save(
    String childId, {
    String? world,
    String? avatarId,
    String? tutorId,
    String? voiceId,
  }) async {
    final j = await _client.put('/api/children/$childId/look', {
      'world': ?world,
      'avatarId': ?avatarId,
      'tutorId': ?tutorId,
      'voiceId': ?voiceId,
    });
    if (j is Map) {
      return _keep(ChildLook.fromJson(j, config, childId: childId));
    }
    // a 204: what was sent is the look now
    final was = _looks[childId] ?? ChildLook.fallback(childId, config);
    final tutor = tutorId != null && tutorId != 'surprise' ? tutorId : null;
    return _keep(
      was.copyWith(
        world: world,
        avatarId: avatarId == 'surprise' ? null : avatarId,
        tutorId: tutor,
        voiceId: voiceId ?? (tutor == null ? null : config.voiceFor(tutor)),
      ),
    );
  }

  /// First run's [step] (`world`, `look`, `tutor`, `meet`) is answered:
  /// the next phone resumes after it (JRN-01). Kept here at once; the
  /// server is told best-effort (a step told twice is harmless).
  Future<void> stepDone(String childId, String step) async {
    final was = _looks[childId];
    if (was != null) {
      _keep(
        was.copyWith(
          needsFirstRun: [
            for (final s in was.needsFirstRun)
              if (s != step) s,
          ],
        ),
      );
    }
    try {
      final j = await _client.post('/api/children/$childId/first-run', {
        'step': step,
      });
      // the same body as GET look
      if (j is Map) _keep(ChildLook.fromJson(j, config, childId: childId));
    } on ApiException catch (e) {
      debugPrint('first run: $step not sent: $e');
    }
  }

  ChildLook _keep(ChildLook look) {
    _looks[look.childId] = look;
    notifyListeners();
    return look;
  }
}
