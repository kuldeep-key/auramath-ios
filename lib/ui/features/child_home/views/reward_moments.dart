import 'package:flutter/material.dart';

import '../../../../data/models/journey_config.dart';
import '../../../../data/repositories/celebration_repository.dart';
import '../../../../data/repositories/rewards_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/celebration.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/theme/tokens.dart';
import 'badge_disc.dart';

/// Builds the reward celebrations (rewards/rules.yaml, REW-01, REW-05,
/// REW-11, REW-16) for one child in their world: each with its next
/// version, its longest length, and tap to skip once seen before; and
/// logs each as it ends (`celebration_shown`, `badge_shown`).
class RewardMoments {
  RewardMoments({
    required this.celebrations,
    required this.config,
    required this.childId,
    this.world = 'detective',
    this.lookId,
  });

  final CelebrationRepository celebrations;
  final JourneyConfig config;
  final String? childId;
  final String world;

  /// The child's look, beside the session badge (AVT-02).
  final String? lookId;

  Future<CelebrationSpec> _spec(
    String moment, {
    required String title,
    required Widget art,
    String? subtitle,
    String? badgeId,
    bool queued = false,
    String? problemId,
    Widget? side,
  }) async {
    final id = childId;
    return CelebrationSpec(
      moment: moment,
      variant: id == null
          ? 1
          : await celebrations.pickVariant(id, moment, world),
      title: title,
      subtitle: subtitle,
      art: art,
      side: side,
      maxDuration: config.maxFor(moment),
      skippable: id != null && await celebrations.seen(id, moment),
      badgeId: badgeId,
      queued: queued,
      problemId: problemId,
    );
  }

  /// REW-01: the session's one badge, with the case it was for, and the
  /// child's look beside it.
  Future<CelebrationSpec> sessionBadge(
    ServerBadge badge, {
    bool queued = false,
  }) => _spec(
    'session_badge',
    title: badge.name,
    subtitle: badge.subtitle,
    badgeId: badge.badgeId.isEmpty ? null : badge.badgeId,
    queued: queued,
    art: BadgeArt(badgeId: badge.badgeId, world: world, size: 150),
    side: lookId == null
        ? null
        : LookPortrait(lookId: lookId!, world: world, size: 90),
  );

  /// REW-05: the kind streak moment. No number, never a loss.
  Future<CelebrationSpec> streak(AppLocalizations l) => _spec(
    'streak_moment',
    title: l.kidStreakMoment,
    art: const Icon(
      Icons.local_fire_department_rounded,
      size: 120,
      color: AuraColors.yellow,
    ),
  );

  /// REW-11: a big badge at the end of the case it was earned in (or the
  /// first solved case of the next session, [Award.queued]). A last stop
  /// and its land are one moment: the land's trophy, with the stop named.
  Future<CelebrationSpec> bigBadge(Award a) {
    final land = a.alsoLand;
    return _spec(
      // the server's moment: a last stop and its land come as one
      // stop_badge moment with alsoLand (the land's trophy, the stop named)
      a.celebration,
      title: land?.name ?? a.name,
      subtitle: land != null ? a.name : null,
      badgeId: land?.badgeId ?? a.badgeId,
      queued: a.queued,
      problemId: a.problemId,
      art: BadgeArt(
        badgeId: land?.badgeId ?? a.badgeId,
        world: world,
        size: 170,
      ),
    );
  }

  /// Logs a celebration that ended.
  void shown(CelebrationSpec spec, CelebrationResult r) {
    celebrations.shown(
      childId,
      moment: spec.moment,
      variant: spec.variant,
      world: world,
      ms: r.ms,
      skipped: r.skipped,
      reducedMotion: r.reducedMotion,
      badge: spec.badgeId == null
          ? null
          : (
              badgeId: spec.badgeId!,
              queued: spec.queued,
              problemId: spec.problemId,
            ),
    );
  }
}

/// A reward badge's art by its catalogue id (`stop.orchard.l1`,
/// `land.orchard`, `habit.bar_builder`, `session.all_by_myself`,
/// `first_case`): `art.badge.<id>.<world>` once Apoorv's art is in the
/// build, else a gold disc with a placeholder mark by kind.
class BadgeArt extends StatelessWidget {
  const BadgeArt({
    super.key,
    required this.badgeId,
    required this.size,
    this.world = 'detective',
  });

  final String badgeId;
  final String world;
  final double size;

  static String markOf(String badgeId) => switch (badgeId.split('.').first) {
    'land' => '🏆',
    'stop' => '🏅',
    'habit' => '🌟',
    'session' => '⭐',
    _ when badgeId.contains('first') => '🔎',
    _ => badgeArt(badgeId),
  };

  @override
  Widget build(BuildContext context) => ArtOr(
    artKey: 'art.badge.$badgeId.$world',
    size: size,
    placeholder: BadgeDisc(art: markOf(badgeId), size: size),
  );
}

/// Loads [load]'s celebrations, plays them in order, then shows [child].
/// While they load, [child] (Home, which the end of a session celebrates
/// over), or with [hold] the play background alone, so nothing else shows
/// first (REW-01: a waiting badge comes before anything else).
class Celebrate extends StatefulWidget {
  const Celebrate({
    super.key,
    required this.load,
    required this.onShown,
    required this.child,
    this.hold = false,
  });

  final bool hold;
  final Future<List<CelebrationSpec>> Function() load;
  final void Function(CelebrationSpec, CelebrationResult) onShown;
  final Widget child;

  @override
  State<Celebrate> createState() => _CelebrateState();
}

class _CelebrateState extends State<Celebrate> {
  late final Future<List<CelebrationSpec>> _moments = widget.load().catchError(
    (Object _) => const <CelebrationSpec>[],
  );

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _moments,
    builder: (_, snap) => switch (snap.data) {
      null when snap.connectionState != ConnectionState.done =>
        widget.hold
            ? const Material(color: AuraColors.blue, child: SizedBox.expand())
            : widget.child,
      final m => CelebrationQueue(
        moments: m ?? const [],
        onShown: widget.onShown,
        child: widget.child,
      ),
    },
  );
}
