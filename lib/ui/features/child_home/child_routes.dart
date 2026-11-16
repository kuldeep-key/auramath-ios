import 'dart:async';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/celebration_repository.dart';
import '../../../data/repositories/look_repository.dart';
import '../../../data/repositories/partner_intro_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/rewards_repository.dart';
import '../../../data/models/lesson_event.dart';
import '../../../data/services/api.dart';
import '../../../deps.dart';
import '../../../routing/paths.dart';
import 'views/after_case_screen.dart';
import 'views/badge_screen.dart';
import 'views/badges_screen.dart';
import 'views/check_screen.dart';
import 'views/choose_today_screen.dart';
import 'views/home_moments.dart';
import 'views/home_screen.dart';
import 'views/meet_partner_screen.dart';
import 'views/pick_avatar_screen.dart';
import 'views/loaded.dart';
import 'views/trail_screen.dart';
import 'views/trail_top_screen.dart';
import 'views/voice_screens.dart';
import 'views/reward_moments.dart';
import 'views/welcome_back_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/motion/celebration.dart';
import '../../core/theme/tokens.dart';
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

  final rewards = RewardsRepository(deps.client);

  /// REW-06: the level badges last served, by id, for the badge's own screen.
  final levelBadges = <String, BadgeInfo>{};
  BadgeInfo? badgeInfo(String? id) => deps.pack.badges[id] ?? levelBadges[id];
  final moments = HomeMomentsSource(rewards: rewards);
  final celebrations = CelebrationRepository(deps.store, deps.visits);

  /// The reward celebrations for the child learning now, in their world,
  /// with their look beside the session badge.
  RewardMoments momentsFor() {
    final id = deps.account.childId;
    final look = deps.looks.cached(id);
    return RewardMoments(
      celebrations: celebrations,
      config: deps.journey,
      childId: id,
      world: look?.world ?? deps.journey.defaultWorld,
      lookId: look?.avatarId ?? lookIdFor(progress.cachedAvatar),
    );
  }

  /// REW-01: the session badge the server holds as not yet shown, read
  /// once per launch for each child.
  ServerBadge? pendingBadge;
  final pendingAsked = <String>{};
  Future<bool> pendingBadgeDue() async {
    final id = deps.account.childId;
    if (id == null || !pendingAsked.add(id)) return false;
    final p = (await rewards.read(id)).pendingSessionBadge;
    if (p == null) return false;
    // its session's badge shows here, not again on Home
    if (p.sessionId case final s?) moments.markShown(s);
    pendingBadge = p.badge;
    return true;
  }

  /// REW-11: the session's big badge, if one came with the case just
  /// solved (or waited from last session, `queued`), once.
  final bigShownIn = <String>{};
  Future<List<CelebrationSpec>> bigBadge() async {
    final session = deps.sessions.lastStop.value?.sessionId;
    if (session == null || bigShownIn.contains(session)) return const [];
    // the case's last batch, and its answer, first
    await deps.sessions.syncNow();
    final award = deps.sessions.awardsFor(session).firstOrNull;
    if (award == null) return const [];
    bigShownIn.add(session);
    return [await momentsFor().bigBadge(award)];
  }

  /// The end of the session just stopped, in rules.yaml's order
  /// (`end_of_session_order`): the streak moment, then the session badge.
  Future<List<CelebrationSpec>> endOfSession(AppLocalizations l) async {
    final m = await moments.next(
      lastStop: deps.sessions.lastStop.value,
      childId: deps.account.childId,
      replied: (id) => switch (deps.sessions.badgeFor(id)) {
        final b? => (id: b.badgeId, name: b.name, says: b.subtitle),
        null => null,
      },
      streakOn: deps.flags.on('streak_moment'),
      // DAT-03: logged after the child's last lesson
      onStreak: (m) => deps.sessions.recordAfterLesson(
        deps.account.childId,
        SpecEvent('streak_moment_shown', {
          'consecutive_days_band': m.band,
          if (m.coveredMissedDay) 'covered_missed_day': true,
        }),
      ),
    );
    final r = momentsFor();
    final badge = m.badge;
    return [
      for (final moment in deps.journey.endOfSessionOrder)
        if (moment == 'streak_moment' && m.streak)
          await r.streak(l)
        else if (moment == 'session_badge' && badge != null)
          await r.sessionBadge((
            // none served yet: shown, not logged as a badge
            badgeId: badge.served?.id ?? '',
            kind: 'session',
            name:
                badge.served?.name ?? HomeMomentCard.draftName(l, badge.reason),
            forWhat: null,
            draftName: badge.served == null,
            subtitle: badge.served?.says,
          )),
    ];
  }

  Widget named(Widget Function(String? name) screen) => FutureBuilder(
    initialData: progress.cachedName,
    future: progress.childName(),
    builder: (_, snap) => screen(snap.data),
  );

  return [
    GoRoute(
      path: Paths.home,
      // REW-01: a badge waiting from a session that ended with the app
      // closed or offline, before anything else; then Welcome back (SES-07)
      redirect: (_, _) async => await pendingBadgeDue()
          ? Paths.badgeWaiting
          : await progress.welcomeBackDue()
          ? Paths.welcomeBack
          : null,
      pageBuilder: (context, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.fade,
        child: named(
          (name) => Celebrate(
            // the end of the session, in rules.yaml's order: REW-05's
            // streak moment (behind streak_moment), then REW-01's badge of
            // the session that just stopped, whatever way it stopped
            load: () => endOfSession(AppLocalizations.of(context)!),
            onShown: (spec, r) => momentsFor().shown(spec, r),
            child: ListenableBuilder(
              listenable: deps.flags,
              builder: (_, _) => HomeScreen(
                name: name,
                grownUps: deps.account.role == Role.device
                    ? Paths.signIn
                    : Paths.kids,
                trail: deps.flags.on('trail'),
                badges:
                    deps.flags.on('badge_cabinet') ||
                    deps.flags.on('mastery_badges'),
                avatar: progress.cachedAvatar,
                // Choose today first, with Quick sums on (LES-14)
                play: deps.flags.on('quick_sums')
                    ? Paths.chooseToday
                    : Paths.lessonNext,
              ),
            ),
          ),
        ),
      ),
    ),
    GoRoute(
      path: Paths.badgeWaiting,
      pageBuilder: (context, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.fade,
        child: Celebrate(
          hold: true,
          load: () async => [
            if (pendingBadge case final b?)
              await momentsFor().sessionBadge(b, queued: true),
          ],
          onShown: (spec, r) {
            pendingBadge = null;
            momentsFor().shown(spec, r);
          },
          child: const _GoHome(),
        ),
      ),
    ),
    GoRoute(
      path: Paths.welcomeBack,
      pageBuilder: (_, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.fade,
        child: named(
          (name) => WelcomeBackScreen(
            name: name,
            caseWaiting: progress.caseWaiting,
            chooseToday: deps.flags.on('quick_sums'),
          ),
        ),
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
        // REW-12: the server's cabinet, earned badges only (behind
        // badge_cabinet); a server before it: the case badges earned on
        // this phone, then the level badges it says were earned (REW-06)
        load: () async {
          final id = deps.account.childId;
          final read = id == null ? null : await rewards.read(id);
          final cabinet = read?.cabinet;
          levelBadges.clear();
          final List<String> earned;
          if (cabinet != null) {
            levelBadges.addAll({
              for (final b in cabinet)
                b.badgeId: BadgeInfo(name: b.name, says: b.name),
            });
            earned = [for (final b in cabinet) b.badgeId];
          } else {
            final mine = await progress.earnedBadges();
            final levels = id == null
                ? const <ServedBadge>[]
                : await rewards.levelBadges(id);
            levelBadges.addAll({
              for (final b in levels)
                b.id: BadgeInfo(name: b.name, says: b.says ?? b.name),
            });
            earned = [
              ...mine,
              for (final b in levels)
                if (!mine.contains(b.id)) b.id,
            ];
          }
          // logged, never shown: how many it showed (REW-20)
          unawaited(deps.visits.record(id, [cabinetOpened(earned.length)]));
          return (earned: earned, world: read?.world ?? 'detective');
        },
        builder: (c) => BadgesScreen(
          earned: c.earned,
          badges: {...deps.pack.badges, ...levelBadges},
          world: c.world,
          onOpen: (badge) => deps.visits.record(deps.account.childId, [
            badgeOpened(badge, from: BadgeOpenedFrom.cabinet),
          ]),
        ),
      ),
    ),
    GoRoute(
      path: '/badges/:badgeId',
      redirect: (_, state) => badgeInfo(state.pathParameters['badgeId']) != null
          ? null
          : Paths.badges,
      pageBuilder: (_, state) {
        final id = state.pathParameters['badgeId']!;
        return MotionPage(
          key: state.pageKey,
          arrive: Arrive.zoom,
          child: BadgeScreen(id: id, badge: badgeInfo(id)!),
        );
      },
    ),
    GoRoute(
      path: Paths.trail,
      builder: (_, _) => Loaded(
        // REW-04: the server's trail (every phone the same), else this
        // phone's
        load: () async {
          final id = deps.account.childId;
          return (
            local: await progress.trail(),
            served: id == null ? null : await rewards.trail(id),
          );
        },
        builder: (t) => (t.served?.atTop ?? t.local.atTop)
            ? const TrailTopScreen()
            : TrailScreen(here: t.local.here, served: t.served),
      ),
    ),
    GoRoute(path: Paths.trailTop, builder: (_, _) => const TrailTopScreen()),
    GoRoute(
      path: Paths.avatar,
      pageBuilder: (_, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.rise,
        child: PickAvatarScreen(
          current: progress.cachedAvatar,
          // ACC-12: the child's own phone uses its device token's route
          // (BE-20); a grown-up's phone edits the child as ever
          onSave: (avatar) async {
            final id = deps.account.childId;
            if (id == null) return;
            if (deps.account.role == Role.device) {
              await deps.family.setAvatar(id, avatar);
            } else {
              await deps.family.editChild(id, {'avatar': avatar});
            }
            progress.avatarPicked(avatar);
            // DAT-03, ACC-12
            await deps.sessions.recordAfterLesson(
              id,
              SpecEvent('avatar_chosen', {'avatar_id': avatar}),
            );
          },
        ),
      ),
    ),
    GoRoute(path: Paths.check, builder: (_, _) => const CheckScreen()),
    GoRoute(
      path: Paths.chooseToday,
      redirect: (_, _) => deps.flags.on('quick_sums') ? null : Paths.lessonNext,
      pageBuilder: (_, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.fade,
        // the selector's suggestion from the last session opened (LES-14)
        child: ChooseTodayScreen(
          suggestQuickSums: suggestsQuickSums(deps.sessions.lastSuggestion),
        ),
      ),
    ),
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
          builder: (a) => Celebrate(
            // REW-11: after the case-solved moment (the lesson's own), the
            // big badge earned in this case, one a session at most; then
            // Y4, Streak and Up ("Try a new skill"), then the next case
            hold: true,
            load: bigBadge,
            onShown: (spec, r) => momentsFor().shown(spec, r),
            child: AfterCaseScreen(
              after: (
                solved: a.solved,
                next: a.next,
                sentBadge: deps.flags.on('report_delivery')
                    ? a.sentBadge
                    : null,
                streak: deps.flags.on('three_in_a_row') && a.streak,
                opened: deps.flags.on('trail') ? a.opened : null,
              ),
              // DAT-03: Y4 says the badge went to the grown-up
              onShared: (badge) => deps.sessions.recordAfterLesson(
                deps.account.childId,
                SpecEvent('badge_shared', {'badge_id': badge, 'shared': true}),
              ),
            ),
          ),
        ),
      ),
    ),
  ];
}

/// Home, once a waiting badge has shown.
class _GoHome extends StatefulWidget {
  const _GoHome();

  @override
  State<_GoHome> createState() => _GoHomeState();
}

class _GoHomeState extends State<_GoHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(Paths.home);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Material(color: AuraColors.blue, child: SizedBox.expand());
}
