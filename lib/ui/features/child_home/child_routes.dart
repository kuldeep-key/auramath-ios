import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/partner_intro_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/rewards_repository.dart';
import '../../../data/models/lesson_event.dart';
import '../../../deps.dart';
import '../../../routing/paths.dart';
import 'views/after_case_screen.dart';
import 'views/badge_screen.dart';
import 'views/badges_screen.dart';
import 'views/check_screen.dart';
import 'views/home_moments.dart';
import 'views/home_screen.dart';
import 'views/meet_partner_screen.dart';
import 'views/loaded.dart';
import 'views/trail_screen.dart';
import 'views/trail_top_screen.dart';
import 'views/voice_screens.dart';
import 'views/welcome_back_screen.dart';
import '../../core/motion/screen_motion.dart';

/// The child's screens around the lesson (Home, Welcome back, badges, trail, after a case, sound and voice).
List<RouteBase> childRoutes(Deps deps) {
  final progress = ProgressRepository(
    pack: deps.pack,
    // only this child's cases: a shared phone holds several children's
    events: () async {
      final id = deps.account.childId;
      final ref = id == null ? null : childRefFor(id);
      return [
        for (final e in await deps.outbox.all())
          if (e.childRef == ref) e,
      ];
    },
    sessions: deps.sessions,
    family: deps.family,
    account: deps.account,
  );

  final moments = HomeMomentsSource(rewards: RewardsRepository(deps.client));

  Widget named(Widget Function(String? name) screen) => FutureBuilder(
    initialData: progress.cachedName,
    future: progress.childName(),
    builder: (_, snap) => screen(snap.data),
  );

  return [
    GoRoute(
      path: Paths.home,
      redirect: (_, _) async =>
          await progress.welcomeBackDue() ? Paths.welcomeBack : null,
      pageBuilder: (_, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.fade,
        child: named(
          (name) => _WithMoment(
            // REW-01: the badge of the session that just stopped, whatever
            // way it stopped; not behind mastery_badges
            load: () => moments.next(lastStop: deps.sessions.lastStop.value),
            builder: (moment) => ListenableBuilder(
              listenable: deps.flags,
              builder: (_, _) => HomeScreen(
                name: name,
                grownUps: deps.account.role == Role.device
                    ? Paths.signIn
                    : Paths.kids,
                trail: deps.flags.on('trail'),
                badges: deps.flags.on('mastery_badges'),
                moment: moment,
              ),
            ),
          ),
        ),
      ),
    ),
    GoRoute(
      path: Paths.welcomeBack,
      pageBuilder: (_, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.fade,
        child: named((name) => WelcomeBackScreen(name: name)),
      ),
    ),
    GoRoute(
      path: Paths.sound,
      pageBuilder: (_, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.rise,
        child: const SoundScreen(),
      ),
    ),
    GoRoute(
      path: Paths.noVoice,
      pageBuilder: (_, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.rise,
        child: const NoVoiceScreen(),
      ),
    ),
    GoRoute(
      path: Paths.badges,
      builder: (_, _) => Loaded(
        load: progress.earnedBadges,
        builder: (earned) =>
            BadgesScreen(earned: earned, badges: deps.pack.badges),
      ),
    ),
    GoRoute(
      path: '/badges/:badgeId',
      redirect: (_, state) =>
          deps.pack.badges.containsKey(state.pathParameters['badgeId'])
          ? null
          : Paths.badges,
      pageBuilder: (_, state) {
        final id = state.pathParameters['badgeId']!;
        return MotionPage(
          key: state.pageKey,
          arrive: Arrive.zoom,
          child: BadgeScreen(id: id, badge: deps.pack.badges[id]!),
        );
      },
    ),
    GoRoute(
      path: Paths.trail,
      builder: (_, _) => Loaded(
        load: progress.trail,
        builder: (t) =>
            t.atTop ? const TrailTopScreen() : TrailScreen(here: t.here),
      ),
    ),
    GoRoute(path: Paths.trailTop, builder: (_, _) => const TrailTopScreen()),
    GoRoute(path: Paths.check, builder: (_, _) => const CheckScreen()),
    GoRoute(
      path: Paths.meetPartner,
      builder: (context, _) => MeetPartnerScreen(
        served: PartnerIntroRepository.lines(deps.pack.policyLines, const []),
        readAloud: deps.flags.on('read_aloud'),
        onSay: deps.voice.say,
        onStart: () async {
          await PartnerIntroRepository(
            deps.store,
          ).markMet(deps.account.childId);
          if (context.mounted) context.go(Paths.lessonNext);
        },
      ),
    ),
    GoRoute(
      path: Paths.afterCase,
      redirect: (_, state) =>
          deps.pack.problems.containsKey(state.uri.queryParameters['next'])
          ? null
          : Paths.home,
      pageBuilder: (_, state) => MotionPage(
        key: state.pageKey,
        arrive: Arrive.zoom,
        child: Loaded(
          key: ValueKey(state.uri.toString()),
          load: () => progress.afterCase(
            state.uri.queryParameters['next']!,
            // a signed-in family whose last send reached the server
            familyHears:
                deps.account.role != Role.none && deps.sessions.online.value,
          ),
          // each moment behind its flag: Y4 report_delivery, Streak
          // three_in_a_row, Up trail
          builder: (a) => AfterCaseScreen(
            after: (
              solved: a.solved,
              next: a.next,
              sentBadge: deps.flags.on('report_delivery') ? a.sentBadge : null,
              streak: deps.flags.on('three_in_a_row') && a.streak,
              opened: deps.flags.on('trail') ? a.opened : null,
            ),
          ),
        ),
      ),
    ),
  ];
}

/// Asks [load] once for this Home, then builds it with the card, or
/// with none while there is nothing to show.
class _WithMoment extends StatefulWidget {
  const _WithMoment({required this.load, required this.builder});

  final Future<HomeMoments> Function() load;
  final Widget Function(Widget? moment) builder;

  @override
  State<_WithMoment> createState() => _WithMomentState();
}

class _WithMomentState extends State<_WithMoment> {
  late final _moments = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _moments,
    builder: (_, snap) {
      final m = snap.data;
      return widget.builder(
        m == null || m.badge == null ? null : HomeMomentCard(moments: m),
      );
    },
  );
}
