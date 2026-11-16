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
import 'views/journey_screens.dart';
import '../../core/parts/journey_art.dart';
import 'views/meet_partner_screen.dart';
import 'views/path_screen.dart';
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

  /// The Homes that have greeted the child (one greeting a visit).
  final greeted = <LocalKey>{};

  /// The child's world now; Detective until the server says.
  String worldNow() =>
      deps.looks.cached(deps.account.childId)?.world ??
      deps.journey.defaultWorld;

  /// The child's tutor now (TTR-01: the default until they choose; one
  /// switched off falls back to it).
  ({String id, String kind}) tutorNow() {
    final config = deps.journey;
    final id = deps.looks.cached(deps.account.childId)?.tutorId;
    final t =
        config.pickable.where((t) => t.id == id).firstOrNull ??
        config.tutorById(config.defaultTutor);
    return (
      id: t?.id ?? config.defaultTutor,
      kind: t?.kind ?? 'grown_up_teacher',
    );
  }

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
      // the tutor cheers beside a badge (Y3, Habit, LandTrophy)
      tutorId: tutorNow().id,
      tutorKind: tutorNow().kind,
    );
  }

  /// Policy line [lineId] in the child's tutor's words: its slots filled
  /// from tutors.yaml and the world's skin, never with the child's name.
  String tutorLine(BuildContext context, String lineId, {String? tutorId}) {
    final l = AppLocalizations.of(context)!;
    final unnamed = l.kidTutorPlaceholderName;
    return deps.journey.tutorLine(
      deps.pack.policyLines[lineId] ?? '',
      tutorId: tutorId ?? tutorNow().id,
      world: worldNow(),
      unnamed: unnamed.substring(0, 1).toLowerCase() + unnamed.substring(1),
    );
  }

  /// The tutor speaks [text] outside a lesson (TTR-03): as it appears if
  /// read-aloud is on, or when the child asks; in [voiceId] this once (a
  /// hello sample), else the child's own voice. Logged as
  /// `read_aloud_played` under the visit (D-60), the line's id only.
  void speak(
    String text,
    String lineId, {
    required bool tapped,
    String? voiceId,
  }) {
    if (text.isEmpty || (!tapped && !deps.flags.on('read_aloud'))) return;
    if (voiceId == null) {
      deps.voice.say(text);
    } else {
      deps.voice.sayIn(text, voiceId);
    }
    unawaited(
      deps.visits.record(deps.account.childId, [
        readAloudPlayed(
          target: 'line',
          trigger: tapped ? ReadTrigger.tap : ReadTrigger.auto,
          stoppedEarly: false,
          lineId: lineId,
        ),
      ]),
    );
  }

  /// JRN-01: the first-run step this child still has to answer, read once
  /// per launch for each child (GET look `needsFirstRun`): its screen, or
  /// null when first run is done. A step the journey skips (one world, or
  /// one tutor, enabled) is marked done without asking.
  final lookAsked = <String>{};
  Future<String?> firstRunAt() async {
    final id = deps.account.childId;
    if (id == null) return null;
    final look = lookAsked.add(id)
        ? await deps.looks.read(id, avatar: progress.cachedAvatar)
        : deps.looks.cached(id);
    for (final step in firstRunSteps) {
      if (!(look?.needsFirstRun.contains(step) ?? false)) continue;
      switch (step) {
        case 'world' when !deps.journey.pickWorld:
        case 'tutor' when !deps.journey.pickTutor:
          await deps.looks.stepDone(id, step);
        case 'world':
          return '${Paths.pickWorld}?first=1';
        case 'look':
          return '${Paths.avatar}?first=1';
        case 'tutor':
          return '${Paths.pickTutor}?first=1';
        case 'meet':
          return '${Paths.meetPartner}?first=1';
      }
    }
    return null;
  }

  /// A choice saved on a picker: in first run, its step is done and Home
  /// opens the next one; else back where the child came from.
  Future<void> chosen(BuildContext context, String step, bool first) async {
    final id = deps.account.childId;
    if (first && id != null) await deps.looks.stepDone(id, step);
    if (!context.mounted) return;
    if (first || !context.canPop()) {
      context.go(Paths.home);
    } else {
      context.pop();
    }
  }

  /// REW-11: the big badges that came with the case just solved (or waited
  /// from last session, `queued`), each once, one after another in the
  /// order the server sent them: what waited longest first, and from one
  /// case the smaller first (Ashutosh, daily catch-up 16 Nov).
  final bigShown = <String>{};
  Future<List<CelebrationSpec>> bigBadge(AppLocalizations l) async {
    final session = deps.sessions.lastStop.value?.sessionId;
    if (session == null) return const [];
    // the case's last batch, and its answer, first
    await deps.sessions.syncNow();
    final due = [
      for (final a in deps.sessions.awardsFor(session))
        if (bigShown.add(a.badgeId)) a,
    ];
    final r = momentsFor();
    return [for (final a in due) await r.bigBadge(a, l: l)];
  }

  /// The end of the session just stopped, in rules.yaml's order
  /// (`end_of_session_order`): the streak moment, then the session badge.
  Future<List<CelebrationSpec>> endOfSession(
    AppLocalizations l, {
    String? reminder,
  }) async {
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
          await r.sessionBadge(
            (
              // none served yet: shown, not logged as a badge
              badgeId: badge.served?.id ?? '',
              kind: 'session',
              name:
                  badge.served?.name ??
                  HomeMomentCard.draftName(l, badge.reason),
              forWhat: null,
              draftName: badge.served == null,
              subtitle: badge.served?.says,
            ),
            l: l,
            reminder: reminder,
          ),
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
      // JRN-01: first, the first-run step still to answer
      redirect: (_, _) async =>
          await firstRunAt() ??
          (await pendingBadgeDue()
              ? Paths.badgeWaiting
              : await progress.welcomeBackDue()
              ? Paths.welcomeBack
              : null),
      pageBuilder: (context, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.fade,
        child: named(
          (name) => Celebrate(
            // the end of the session, in rules.yaml's order: REW-05's
            // streak moment (behind streak_moment), then REW-01's badge of
            // the session that just stopped, whatever way it stopped
            load: () => endOfSession(
              AppLocalizations.of(context)!,
              // Y3: the tutor's AI reminder, once, at the session's end
              reminder: tutorLine(context, 'line.tutor.ai-reminder'),
            ),
            onShown: (spec, r) => momentsFor().shown(spec, r),
            child: ListenableBuilder(
              listenable: Listenable.merge([deps.flags, deps.looks]),
              builder: (context, _) => HomeScreen(
                // AVT-02, JRN-02: the look and the tutor, as they are now
                lookId:
                    deps.looks.cached(deps.account.childId)?.avatarId ??
                    (progress.cachedAvatar == null
                        ? null
                        : lookIdFor(progress.cachedAvatar)),
                world: worldNow(),
                tutorId: tutorNow().id,
                tutorKind: tutorNow().kind,
                greeting: tutorLine(context, 'line.home.greeting'),
                // spoken once as this Home opens, again on a tap
                onGreet: ({required tapped}) {
                  if (!tapped && !greeted.add(s.pageKey)) return;
                  speak(
                    tutorLine(context, 'line.home.greeting'),
                    'line.home.greeting',
                    tapped: tapped,
                  );
                },
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
              await momentsFor().sessionBadge(
                b,
                queued: true,
                l: AppLocalizations.of(context)!,
                reminder: tutorLine(context, 'line.tutor.ai-reminder'),
              ),
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
          tutorId: tutorNow().id,
          tutorKind: tutorNow().kind,
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
          child: BadgeScreen(id: id, badge: badgeInfo(id)!, world: worldNow()),
        );
      },
    ),
    GoRoute(
      path: Paths.trail,
      builder: (_, _) => Loaded(
        // REW-04: the server's trail (every phone the same), else this
        // phone's
        // phone's. From v0.5.4 it is drawn as a path (JRN-03); opening it
        // logs trail_opened (D-60: under the visit)
        load: () async {
          final id = deps.account.childId;
          unawaited(deps.visits.record(id, const [trailOpened]));
          final read = id == null ? null : await rewards.read(id);
          return (
            local: await progress.trail(),
            served: id == null ? null : await rewards.trail(id),
            lands: read?.lands,
            world: read?.world ?? deps.journey.defaultWorld,
          );
        },
        builder: (t) => switch (t.lands) {
          final lands? when lands.isNotEmpty => PathScreen(
            lands: lands,
            world: t.world,
            lookId:
                deps.looks.cached(deps.account.childId)?.avatarId ??
                lookIdFor(progress.cachedAvatar),
          ),
          _ when t.served?.atTop ?? t.local.atTop => const TrailTopScreen(),
          _ => TrailScreen(here: t.local.here, served: t.served),
        },
      ),
    ),
    GoRoute(path: Paths.trailTop, builder: (_, _) => const TrailTopScreen()),
    GoRoute(
      path: Paths.avatar,
      pageBuilder: (context, s) {
        final first = s.uri.queryParameters['first'] == '1';
        final l = AppLocalizations.of(context)!;
        return MotionPage(
          key: s.pageKey,
          arrive: Arrive.rise,
          // ACC-12, AVT-01: the eight looks and Surprise me, in first run
          // and on the Me screen; never labelled or sorted by gender
          child: JourneyPicker(
            prompt: deps.pack.policyLines['line.pick.look'] ?? l.kidMyLook,
            firstRun: first,
            surprise: true,
            current:
                deps.looks.cached(deps.account.childId)?.avatarId ??
                (progress.cachedAvatar == null
                    ? null
                    : lookIdFor(progress.cachedAvatar)),
            choices: lookChoices(l, deps.journey, worldNow()),
            // BE-20's 403: this phone may not set it; a grown-up does
            failedText: (e) => e is ApiException && e.status == 403
                ? l.kidPickAvatarAskGrownUp
                : null,
            onChoose: (look) async {
              final id = deps.account.childId;
              if (id == null) return;
              try {
                await deps.looks.save(id, avatarId: look);
              } on ApiException catch (e) {
                if (e.status != 404) rethrow;
                // a server before looks: the avatar route, which takes
                // look ids too (contract 4); a grown-up's phone edits the
                // child as ever
                if (deps.account.role == Role.device) {
                  await deps.family.setAvatar(id, look);
                } else {
                  await deps.family.editChild(id, {'avatar': look});
                }
              }
              progress.avatarPicked(look);
              // DAT-03, ACC-12
              await deps.sessions.recordAfterLesson(
                id,
                SpecEvent('avatar_chosen', {'avatar_id': look}),
              );
              if (context.mounted) await chosen(context, 'look', first);
            },
          ),
        );
      },
    ),
    GoRoute(
      path: Paths.me,
      pageBuilder: (context, s) => MotionPage(
        key: s.pageKey,
        arrive: Arrive.rise,
        child: named(
          (name) => ListenableBuilder(
            listenable: deps.looks,
            builder: (_, _) => MeScreen(
              name: name,
              lookId:
                  deps.looks.cached(deps.account.childId)?.avatarId ??
                  lookIdFor(progress.cachedAvatar),
              tutorId: tutorNow().id,
              tutorKind: tutorNow().kind,
              world: worldNow(),
              // JRN-02: My world only with the worlds switch on and two or
              // more worlds enabled
              showWorld: deps.flags.on('worlds') && deps.journey.pickWorld,
            ),
          ),
        ),
      ),
    ),
    GoRoute(
      path: Paths.pickTutor,
      pageBuilder: (context, s) {
        final first = s.uri.queryParameters['first'] == '1';
        final l = AppLocalizations.of(context)!;
        return MotionPage(
          key: s.pageKey,
          arrive: Arrive.rise,
          // TTR-01, TTR-06: the enabled tutors, each saying hello in its
          // own voice, and Surprise me
          child: JourneyPicker(
            prompt: deps.pack.policyLines['line.pick.tutor'] ?? l.kidMyTutor,
            firstRun: first,
            surprise: true,
            tile: 110,
            current: first ? null : tutorNow().id,
            choices: tutorChoices(l, deps.journey, worldNow()),
            onHear: (tutor) => speak(
              tutorLine(context, 'line.tutor.hello', tutorId: tutor),
              'line.tutor.hello',
              tapped: true,
              voiceId: deps.journey.voiceFor(tutor),
            ),
            onChoose: (tutor) async {
              final id = deps.account.childId;
              if (id == null) return;
              // a new tutor starts with its own default voice
              await deps.looks.save(id, tutorId: tutor);
              if (context.mounted) await chosen(context, 'tutor', first);
            },
          ),
        );
      },
    ),
    GoRoute(
      path: Paths.pickVoice,
      pageBuilder: (context, s) {
        final l = AppLocalizations.of(context)!;
        return MotionPage(
          key: s.pageKey,
          arrive: Arrive.rise,
          // TTR-06: any enabled voice for the tutor, each heard first
          child: JourneyPicker(
            prompt: l.kidMyVoice,
            current:
                deps.looks.cached(deps.account.childId)?.voiceId ??
                deps.journey.voiceFor(tutorNow().id),
            choices: voiceChoices(l, deps.journey),
            onHear: (voice) => speak(
              tutorLine(context, 'line.tutor.hello'),
              'line.tutor.hello',
              tapped: true,
              voiceId: voice,
            ),
            onChoose: (voice) async {
              final id = deps.account.childId;
              if (id == null) return;
              await deps.looks.save(id, voiceId: voice);
              if (context.mounted) await chosen(context, 'voice', false);
            },
          ),
        );
      },
    ),
    GoRoute(
      path: Paths.pickWorld,
      pageBuilder: (context, s) {
        final first = s.uri.queryParameters['first'] == '1';
        final l = AppLocalizations.of(context)!;
        return MotionPage(
          key: s.pageKey,
          arrive: Arrive.rise,
          // REW-22: the enabled worlds, then greyed Coming soon tiles with
          // no names; a change applies from the next session (REW-17)
          child: JourneyPicker(
            prompt: deps.pack.policyLines['line.pick.world'] ?? l.kidMyWorld,
            firstRun: first,
            current: worldNow(),
            choices: worldChoices(deps.journey),
            disabled: deps.journey.comingSoonWorlds,
            disabledLabel: l.kidComingSoon,
            onChoose: (world) async {
              final id = deps.account.childId;
              if (id == null) return;
              await deps.looks.save(id, world: world);
              if (context.mounted) await chosen(context, 'world', first);
            },
          ),
        );
      },
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
      builder: (context, s) {
        final first = s.uri.queryParameters['first'] == '1';
        final tutor = tutorNow();
        // AI-07, TTR-01: the child's tutor introduces itself
        // (line.tutor.intro), its name from tutors.yaml and the child's
        // role from the world; never the child's name (NFR-08)
        final intro = tutorLine(context, 'line.tutor.intro');
        return MeetPartnerScreen(
          served: intro.isEmpty
              ? PartnerIntroRepository.lines(deps.pack.policyLines, const [])
              : [intro],
          readAloud: deps.flags.on('read_aloud'),
          figure: TutorFigure(
            tutorId: tutor.id,
            kind: tutor.kind,
            world: worldNow(),
            size: 140,
          ),
          onSay: (text) => speak(
            text,
            intro.isEmpty ? 'line.intro.hello' : 'line.tutor.intro',
            tapped: true,
          ),
          onStart: () async {
            await PartnerIntroRepository(
              deps.store,
            ).markMet(deps.account.childId);
            if (!context.mounted) return;
            // JRN-01: first run goes on to Home; before a lesson, the lesson
            if (first) {
              await chosen(context, 'meet', true);
            } else {
              context.go(Paths.lessonNext);
            }
          },
        );
      },
    ),
    GoRoute(
      path: Paths.afterCase,
      redirect: (_, state) =>
          deps.pack.problems.containsKey(state.uri.queryParameters['next'])
          ? null
          : Paths.home,
      pageBuilder: (context, state) => MotionPage(
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
            // big badges due at this case, one after another; then
            // Y4, Streak and Up ("Try a new skill"), then the next case
            hold: true,
            load: () => bigBadge(AppLocalizations.of(context)!),
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
