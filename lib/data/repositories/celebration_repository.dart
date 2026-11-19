import 'package:auramath_engine/auramath_engine.dart';

import '../services/key_store.dart';
import 'visit_repository.dart';

/// A badge a celebration shows (REW-11): logged as `badge_shown` with it.
/// [alsoBadgeId]: a second badge the same moment shows (a last stop with
/// its land, H3), logged too.
typedef ShownBadge = ({
  String badgeId,
  bool queued,
  String? problemId,
  String? alsoBadgeId,
});

/// What the phone remembers about celebrations (rewards/rules.yaml
/// `celebrations.global`), and how each one is logged:
///
/// - the version played last, per child, moment and world, so the next is
///   another (`variant_pick: rotate_never_repeat_last`), of at least three
///   (`variants_per_world_at_least`)
/// - whether the child has seen a moment before: tap to skip only after
///   the first time (`tap_to_skip: after_first_view`). The rules count that
///   per child across devices; this phone knows its own views only
/// - `celebration_shown` (and `badge_shown` for a badge): in the child's
///   sitting's open session while there is one ([inSitting], H1), so the
///   server reads them with the lesson; else through the visit's events
///   (D-60)
class CelebrationRepository {
  CelebrationRepository(this._store, this._visits, {this.inSitting});

  final KeyStore _store;
  final VisitRepository _visits;

  /// Writes events in the child's open sitting's session; false when none
  /// is open (`SessionRepository.recordInSitting`).
  final Future<bool> Function(String childId, List<SpecEvent> events)?
  inSitting;

  /// rules.yaml `variants_per_world_at_least`.
  static const variants = 3;

  String _key(String childId, String moment, String world) =>
      'celebration.$childId.$moment.$world';

  /// The version to play now, and remembered as the last.
  Future<int> pickVariant(String childId, String moment, String world) async {
    final key = _key(childId, moment, world);
    final last = int.tryParse(await _store.read(key) ?? '');
    final next = nextVariant(last, variants);
    await _store.write(key, '$next');
    return next;
  }

  /// True once the child has seen [moment] on this phone: it may be
  /// skipped with a tap.
  Future<bool> seen(String childId, String moment) async =>
      await _store.read('celebration.seen.$childId.$moment') == '1';

  String _playedKey(String childId) => 'badges.played.$childId';

  /// The big badges [childId] has been shown on this phone, on any launch.
  /// The server names a big badge again (`queued: true`) until it has a
  /// `badge_shown` for it; one already played here isn't played again
  /// while that is on its way.
  Future<Set<String>> played(String childId) async =>
      (await _store.read(
        _playedKey(childId),
      ))?.split('\n').where((s) => s.isNotEmpty).toSet() ??
      {};

  /// Logs a celebration that played [ms], skipped or not, still or moving,
  /// with the [badge] it showed.
  Future<void> shown(
    String? childId, {
    required String moment,
    required int variant,
    required String world,
    required int ms,
    required bool skipped,
    required bool reducedMotion,
    ShownBadge? badge,
  }) async {
    if (childId == null) return;
    await _store.write('celebration.seen.$childId.$moment', '1');
    if (badge != null) {
      await _store.write(
        _playedKey(childId),
        {
          ...await played(childId),
          badge.badgeId,
          ?badge.alsoBadgeId,
        }.join('\n'),
      );
    }
    final events = [
      celebrationShown(
        moment: moment,
        variant: variant,
        world: world,
        ms: ms,
        skipped: skipped,
        reducedMotion: reducedMotion,
      ),
      if (badge?.alsoBadgeId case final also?)
        badgeShown(also, queued: badge!.queued),
      if (badge != null) badgeShown(badge.badgeId, queued: badge.queued),
    ];
    if (await inSitting?.call(childId, events) ?? false) return;
    await _visits.record(childId, events);
  }
}
