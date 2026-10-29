import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/lesson_event.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/services/outbox_db.dart';
import '../../../deps.dart';
import '../../../routing/paths.dart';
import 'views/after_case_screen.dart';
import 'views/badge_screen.dart';
import 'views/badges_screen.dart';
import 'views/check_screen.dart';
import 'views/home_screen.dart';
import 'views/loaded.dart';
import 'views/trail_screen.dart';
import 'views/trail_top_screen.dart';
import 'views/voice_screens.dart';
import 'views/welcome_back_screen.dart';

/// The child's screens around the lesson (Home, Welcome back, badges, trail, after a case, sound and voice).
List<RouteBase> childRoutes(Deps deps) {
  final progress = ProgressRepository(
    pack: deps.pack,
    events: () => _savedEvents(deps.outbox),
    sessions: deps.sessions,
    family: deps.family,
    account: deps.account,
  );

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
      builder: (_, _) => named(
        (name) => HomeScreen(
          name: name,
          grownUps: deps.account.role == Role.device
              ? Paths.signIn
              : Paths.kids,
        ),
      ),
    ),
    GoRoute(
      path: Paths.welcomeBack,
      builder: (_, _) => named((name) => WelcomeBackScreen(name: name)),
    ),
    GoRoute(path: Paths.sound, builder: (_, _) => const SoundScreen()),
    GoRoute(path: Paths.noVoice, builder: (_, _) => const NoVoiceScreen()),
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
      builder: (_, state) {
        final id = state.pathParameters['badgeId']!;
        return BadgeScreen(id: id, badge: deps.pack.badges[id]!);
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
      path: Paths.afterCase,
      redirect: (_, state) =>
          deps.pack.problems.containsKey(state.uri.queryParameters['next'])
          ? null
          : Paths.home,
      builder: (_, state) => Loaded(
        key: ValueKey(state.uri.toString()),
        load: () => progress.afterCase(
          state.uri.queryParameters['next']!,
          // a signed-in family whose last send reached the server
          familyHears:
              deps.account.role != Role.none && deps.sessions.online.value,
        ),
        builder: (after) => AfterCaseScreen(after: after),
      ),
    ),
  ];
}

// ponytail: OutboxDb can't list every saved event yet, so the badges, the
// trail and the streak see only the latest case; swap for the full log
// (`deps.outbox.all()`) once the lead adds it.
Future<List<LessonEvent>> _savedEvents(OutboxDb db) async {
  final id = await db.lastSessionId();
  return id == null ? const [] : db.forSession(id);
}
