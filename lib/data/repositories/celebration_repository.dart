import 'package:auramath_engine/auramath_engine.dart';

import '../services/key_store.dart';
import 'visit_repository.dart';

/// A badge a celebration shows (REW-11): logged as `badge_shown` with it.
typedef ShownBadge = ({String badgeId, bool queued, String? problemId});

/// What the phone remembers about celebrations (rewards/rules.yaml
/// `celebrations.global`), and how each one is logged:
///
/// - the version played last, per child, moment and world, so the next is
///   another (`variant_pick: rotate_never_repeat_last`), of at least three
///   (`variants_per_world_at_least`)
/// - whether the child has seen a moment before: tap to skip only after
///   the first time (`tap_to_skip: after_first_view`). The rules count that
///   per child across devices; this phone knows its own views only
/// - `celebration_shown` (and `badge_shown` for a badge) through the
///   visit's events (D-60), from R1
class CelebrationRepository {
  CelebrationRepository(this._store, this._visits);

  final KeyStore _store;
  final VisitRepository _visits;

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
    await _visits.record(childId, [
      celebrationShown(
        moment: moment,
        variant: variant,
        world: world,
        ms: ms,
        skipped: skipped,
        reducedMotion: reducedMotion,
      ),
      if (badge != null) badgeShown(badge.badgeId, queued: badge.queued),
    ]);
  }
}
