import 'package:flutter/material.dart';

import '../../../../data/models/journey_config.dart';
import '../../../../data/repositories/celebration_repository.dart';
import '../../../../data/repositories/rewards_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/celebration.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/theme/tokens.dart';
import 'badge_disc.dart';
import 'badge_shapes.dart';
import 'play_moment.dart';

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
    this.tutorId,
    this.tutorKind = 'grown_up_teacher',
  });

  final CelebrationRepository celebrations;
  final JourneyConfig config;
  final String? childId;
  final String world;

  /// The child's look, beside the session badge (AVT-02).
  final String? lookId;

  /// The child's tutor, cheering beside a badge (Y3, Habit, LandTrophy).
  final String? tutorId;
  final String tutorKind;

  Widget? _tutor(double size) => tutorId == null
      ? null
      : TutorFigure(
          tutorId: tutorId!,
          kind: tutorKind,
          world: world,
          size: size,
          state: TutorState.cheering,
        );

  Future<CelebrationSpec> _spec(
    String moment, {
    required String title,
    required Widget art,
    String? subtitle,
    String? badgeId,
    String? alsoBadgeId,
    bool queued = false,
    String? problemId,
    Widget? side,
    String? ribbon,
    String? heading,
    String? line,
    Widget? tutor,
    Widget? walker,
    String? layout,
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
      ribbon: ribbon,
      heading: heading,
      line: line,
      tutor: tutor,
      walker: walker,
      layout: layout,
      maxDuration: config.maxFor(moment),
      skippable: id != null && await celebrations.seen(id, moment),
      badgeId: badgeId,
      alsoBadgeId: alsoBadgeId,
      queued: queued,
      problemId: problemId,
    );
  }

  /// REW-01: the session's one badge (Y3): "Today's badge", the badge
  /// with the tutor cheering beside it, the case it was for, and the
  /// tutor's AI reminder ([reminder], `line.tutor.ai-reminder`).
  Future<CelebrationSpec> sessionBadge(
    ServerBadge badge, {
    bool queued = false,
    AppLocalizations? l,
    String? reminder,
  }) => _spec(
    'session_badge',
    title: badge.name,
    subtitle: badge.subtitle,
    badgeId: badge.badgeId.isEmpty ? null : badge.badgeId,
    queued: queued,
    heading: l?.kidTodaysBadge,
    line: reminder,
    art: BadgeArt(badgeId: badge.badgeId, world: world, size: 200),
    tutor: _tutor(104),
    // the child's look beside it until the tutor is known (AVT-02)
    side: tutorId != null || lookId == null
        ? null
        : LookPortrait(lookId: lookId!, world: world, size: 90),
  );

  /// REW-05: the kind streak moment (Streak): a star, "You came back!"
  /// and one kind line. No number, never a loss, never the child's name.
  Future<CelebrationSpec> streak(AppLocalizations l) => _spec(
    'streak_moment',
    title: l.kidKeepComingBack,
    ribbon: l.kidCameBack,
    art: const Art('🌟', size: 110),
  );

  /// REW-11: a big badge at the end of the case it was earned in (or the
  /// first solved case of the next session, [Award.queued]). A last stop
  /// and its land are one moment: the land's trophy, with the stop named.
  /// Drawn as the prototype's LevelUp (a stop), Habit, LandTrophy, or First
  /// Case flying into the cabinet.
  ///
  /// A passed level is the peak moment (Figma section 15, 17 Nov): "You
  /// reached the peak!", the land's medal on its peak under the summit
  /// flag, the land's name, the path running on into the next land and
  /// "A new land opens: [PeakNext.next]." (with the level number switch
  /// off: never a level number, REW-03). After the last level, "You
  /// reached the top!" and "You climbed every land in the Orchard!".
  Future<CelebrationSpec> bigBadge(
    Award a, {
    AppLocalizations? l,
    PeakNext? peak,
  }) {
    final land = a.alsoLand;
    final id = land?.badgeId ?? a.badgeId;
    final layout = land != null
        ? 'land_badge'
        : switch (a.kind) {
            'land' => 'land_badge',
            'habit' => 'habit_badge',
            'skill_mastered' => 'stop_badge',
            'first_case' => 'first_badge',
            _ => a.celebration,
          };
    return _spec(
      // the server's moment; a last stop and its land come as one award
      // with alsoLand, which plays as the land's moment (its trophy, the
      // stop named, land_badge's length) and logs both as shown (H3)
      land != null ? 'land_badge' : a.celebration,
      layout: layout,
      title: layout == 'first_badge'
          ? (l?.kidIntoYourBadges ?? a.name)
          : land?.name ?? a.name,
      subtitle: layout == 'first_badge'
          ? l?.kidBadgeCabinet
          : land != null
          ? a.name
          : null,
      badgeId: id,
      alsoBadgeId: land != null ? a.badgeId : null,
      queued: a.queued,
      problemId: a.problemId,
      heading: layout == 'stop_badge'
          ? (peak?.last ?? false ? l?.kidReachedTop : l?.kidReachedPeak)
          : null,
      ribbon: switch (layout) {
        'stop_badge' => null,
        'habit_badge' => l?.kidNewBadge,
        'land_badge' => l?.kidLandTrophy,
        _ => null,
      },
      line: switch (layout) {
        'stop_badge' when l != null && peak != null =>
          peak.last
              ? l.kidClimbedEveryLand(inLine(peak.path))
              : peak.next == null
              ? null
              : l.kidNewLandOpens(peak.next!),
        'habit_badge' when l != null => BadgeArt.habitLine(l, id),
        'land_badge' => l?.kidEveryStop,
        _ => null,
      },
      tutor: _tutor(layout == 'first_badge' ? 170 : 104),
      walker: layout == 'stop_badge' && lookId != null && !(peak?.last ?? false)
          ? LookPortrait(lookId: lookId!, world: world, size: 34)
          : null,
      art: layout == 'stop_badge'
          ? PeakArt(
              last: peak?.last ?? false,
              medal: BadgeArt(badgeId: id, world: world, size: 96, glint: true),
            )
          : BadgeArt(
              badgeId: id,
              world: world,
              size: switch (layout) {
                'stop_badge' => 176,
                'land_badge' => 217,
                'first_badge' => 133,
                _ => 200,
              },
              glint: layout == 'stop_badge',
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
              alsoBadgeId: spec.alsoBadgeId,
            ),
    );
  }
}

/// A reward badge's art by its catalogue id (`stop.orchard.l1`,
/// `land.orchard`, `habit.bar_builder`, `session.all_by_myself`,
/// `first_case`): `art.badge.<id>.<world>` once Apoorv's art is in the
/// build, else the prototype's shape by kind (`cabArt`): a stop's medal, a
/// habit's hexagon, a land's trophy, a session badge's gold disc. [size] is
/// the prototype's: a medal or hexagon that wide, a trophy 0.92 of it,
/// First Case 0.9.
class BadgeArt extends StatelessWidget {
  const BadgeArt({
    super.key,
    required this.badgeId,
    required this.size,
    this.world = 'detective',
    this.glint = false,
  });

  final String badgeId;
  final String world;
  final double size;

  /// A stop medal's star glint (LevelUp).
  final bool glint;

  /// The prototype's `SBADGES` and `HABITS` pictures.
  static String markOf(String badgeId) => switch (badgeId.split('.').last) {
    'first_case' => '🔍',
    'in_your_head' => '💡',
    'read_carefully' => '📖',
    'checked_it' => '🔎',
    'all_by_myself' => '✋',
    'back_on_track' => '🧭',
    'used_a_clue' => '🗝️',
    'kept_going' => '🥾',
    'case_cracked' => '⭐',
    'good_start' => '🌱',
    'bar_builder' => '🧱',
    'careful_reader' => '📖',
    'learn_it_do_it' => '🎓',
    'double_checker' => '✅',
    'memory_keeper' => '🧠',
    'teacher' => '🍎',
    _ when badgeId.startsWith('land') => '🏆',
    _ when badgeId.startsWith('stop') => '🏅',
    _ when badgeId.startsWith('habit') => '🌟',
    _ when badgeId.startsWith('session') => '⭐',
    _ => badgeArt(badgeId),
  };

  /// A habit badge's line (Habit, B2), DRAFT; null for one without.
  static String? habitLine(AppLocalizations l, String badgeId) =>
      switch (badgeId) {
        'habit.bar_builder' => l.kidHabitBarBuilder,
        'habit.careful_reader' => l.kidHabitCarefulReader,
        'habit.learn_it_do_it' => l.kidHabitLearnItDoIt,
        'habit.double_checker' => l.kidHabitDoubleChecker,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final kind = badgeId.split('.').first;
    final Widget shape = switch (kind) {
      'stop' => MedalBadge(size: size, glint: glint),
      'habit' => HabitBadge(size: size, emoji: markOf(badgeId)),
      'land' => TrophyBadge(size: (size * 0.92).roundToDouble()),
      _ when badgeId.contains('first_case') => GoldDisc(
        emoji: markOf(badgeId),
        size: (size * 0.9).roundToDouble(),
      ),
      _ => GoldDisc(emoji: markOf(badgeId), size: size),
    };
    final key = 'art.badge.$badgeId.$world';
    // the shapes keep their own heights (a medal 1.05 × its width)
    if (ArtAssets.pathOf(key) == null) return ExcludeSemantics(child: shape);
    return ArtOr(artKey: key, size: size, placeholder: shape);
  }
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

/// What comes after a passed level on the path (Figma section 15): the
/// next land's name, or [last] when it was the last level of [path].
typedef PeakNext = ({String? next, bool last, String path});

/// A name as it reads inside a line: "The Orchard" becomes "the Orchard".
String inLine(String name) =>
    name.startsWith('The ') ? 'the ${name.substring(4)}' : name;

/// The peak moment's art (Figma section 15 LevelUp): the land's medal on
/// its peak, under the summit flag; a sand hill for the last land's top.
class PeakArt extends StatelessWidget {
  const PeakArt({super.key, required this.medal, this.last = false});

  final Widget medal;
  final bool last;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    height: 190,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _PeakPainter(last: last)),
        ),
        Positioned(top: 62, child: medal),
      ],
    ),
  );
}

class _PeakPainter extends CustomPainter {
  const _PeakPainter({required this.last});

  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    const navy = Color(0xFF0F2A73);
    final w = size.width, h = size.height;
    final hill = Path()
      ..moveTo(4, h - 6)
      ..quadraticBezierTo(w * .3, h * .5, w / 2 - 18, h * .36)
      ..quadraticBezierTo(w / 2, h * .3, w / 2 + 18, h * .36)
      ..quadraticBezierTo(w * .7, h * .5, w - 4, h - 6)
      ..close();
    canvas.drawPath(
      hill,
      Paint()..color = last ? const Color(0xFFE2D57A) : const Color(0xFF9EDB9A),
    );
    canvas.drawPath(
      hill,
      Paint()
        ..color = navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    // the summit flag
    final x = w / 2;
    canvas.drawLine(
      Offset(x, h * .34),
      Offset(x, 6),
      Paint()
        ..color = const Color(0xFF6E4525)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final flag = Path()
      ..moveTo(x + 2, 6)
      ..lineTo(x + 46, 6)
      ..lineTo(x + 36, 20)
      ..lineTo(x + 46, 34)
      ..lineTo(x + 2, 34)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFFFC531));
    canvas.drawPath(
      flag,
      Paint()
        ..color = navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(Offset(x + 20, 20), 5, Paint()..color = navy);
  }

  @override
  bool shouldRepaint(_PeakPainter old) => old.last != last;
}
